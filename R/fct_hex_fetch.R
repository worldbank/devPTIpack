#' Fetch hex-level indicator data from registry parquet endpoints
#'
#' Reads every variable in `vars` from its parquet source using
#' `arrow::open_dataset()` with predicate pushdown so only the hexagons
#' matching `hex_ids` are transferred. Year resolution (arch-11
#' §"Year resolution") is applied automatically before fetching.
#'
#' `fetch_hex_data()` has no registry knowledge of its own: all
#' parquet paths and column names are already embedded in the
#' `pti_hex_var` descriptors by [use_hex_vars()].
#'
#' **Resolution bridge (H5 grids):** when `hex_ids` are at H3
#' resolution 5 and the source data is at H6, each H5 cell is
#' transparently expanded to its seven H6 children for the fetch,
#' then the H6 values are aggregated back to H5 using each
#' variable's `weight`/`fun` strategy. Finer-than-source grids
#' (H7 or higher) produce an actionable error.
#'
#' **Temporal variables** are fetched in long format and pivoted wide
#' before returning. Column names follow the convention
#' `<canonical_name>_<resolved_year>`.
#'
#' @param hex_ids Character vector of H3 cell IDs. Comes from
#'   `hex_layer$admin9Pcod` (output of [make_hex_grid()]).
#' @param vars Named list of `pti_hex_var` descriptors as returned by
#'   [use_hex_vars()]. Year resolution is applied before fetching.
#' @param dataset_loader Optional. A function `f(path)` that opens a
#'   data source and returns an object supporting [dplyr::filter()],
#'   [dplyr::select()], and [dplyr::collect()]. Defaults to
#'   [arrow::open_dataset()]. Supply a stub in unit tests to keep
#'   them network-free.
#' @param available_years_lookup Optional named list of integer vectors,
#'   keyed by (unsuffixed) canonical variable name. Passed to
#'   [resolve_years_for_vars()] as its `available_years_lookup` seam.
#'   When `NULL` (default), `get_available_years()` is called per
#'   temporal variable. Supply a stub in unit tests to stay network-free.
#'
#' @return A tibble with columns: `hex_id`, `population` (always the
#'   first indicator column), then one column per non-temporal variable
#'   and one `<canonical_name>_<year>` column per (temporal variable ×
#'   resolved year).
#'
#' @importFrom dplyr filter select collect left_join group_by summarise
#'   across all_of rename
#' @importFrom tidyr pivot_wider
#' @importFrom cli cli_warn cli_abort cli_progress_step cli_progress_done
#' @importFrom h3jsr get_res get_children
#' @importFrom httr2 request req_perform req_body_json resp_body_json
#' @family data-input
#' @export
#'
#' @examples
#' \dontrun{
#' my_shp  <- readRDS("app-data/shapes.rds")
#' hex_ids <- my_shp$admin9_Hexagon$admin9Pcod
#' vars    <- use_hex_vars("flood_exposure_15cm_1in100")
#' hex_data <- fetch_hex_data(hex_ids, vars)
#' }
fetch_hex_data <- function(hex_ids, vars, dataset_loader = NULL,
                           available_years_lookup = NULL) {

  # ── 1. Validate inputs ──────────────────────────────────────────────
  hex_ids <- as.character(hex_ids)
  if (length(hex_ids) == 0L) {
    cli::cli_abort("'hex_ids' must be non-empty.")
  }
  if (!is.list(vars) || length(vars) == 0L) {
    cli::cli_abort("'vars' must be a non-empty list of pti_hex_var objects.")
  }
  bad <- !vapply(vars, inherits, logical(1L), what = "pti_hex_var")
  if (any(bad)) {
    cli::cli_abort(c(
      "'vars' must contain only pti_hex_var objects.",
      "i" = "Use {.fn use_hex_vars} to build a valid vars list."
    ))
  }

  # ── 2. Resolve years ────────────────────────────────────────────────
  vars <- resolve_years_for_vars(vars,
                                 available_years_lookup = available_years_lookup)

  # ── 3. Detect resolution; set up bridge if H5 ───────────────────────
  hex_res    <- h3jsr::get_res(hex_ids[[1L]])
  source_res <- 6L  # all current registry sources are H6

  if (hex_res > source_res) {
    cli::cli_abort(c(
      "Pre-computed data is at H{source_res}; hex grid is at H{hex_res}.",
      "i" = "Set {.code HEX_RESOLUTION} to {source_res} or {source_res - 1L} \\
in {.file 00-master.R}."
    ))
  }

  if (hex_res < (source_res - 1L)) {
    cli::cli_abort(c(
      "H{hex_res} grids are not supported; only H{source_res} (direct) \\
and H{source_res - 1L} (with bridge) are.",
      "i" = "Set {.code HEX_RESOLUTION} to {source_res} or {source_res - 1L} \\
in {.file 00-master.R}."
    ))
  }

  if (length(hex_ids) > 10000L) {
    cli::cli_warn(c(
      "Large hex grid: {.val {length(hex_ids)}} cells.",
      "i" = "Fetch may be slow. Consider a coarser {.code HEX_RESOLUTION}."
    ))
  }

  use_bridge <- hex_res < source_res
  if (use_bridge) {
    children_list <- h3jsr::get_children(hex_ids, res = source_res)
    fetch_ids <- unlist(children_list)
    parent_map <- data.frame(
      hex_id_child  = fetch_ids,
      hex_id_parent = rep(hex_ids, lengths(children_list)),
      stringsAsFactors = FALSE
    )
  } else {
    fetch_ids  <- hex_ids
    parent_map <- NULL
  }

  # ── 4. Default loader ────────────────────────────────────────────────
  if (is.null(dataset_loader)) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg arrow} is required for {.fn fetch_hex_data}.",
        "i" = "Install it with {.run install.packages('arrow')}."
      ))
    }
    dataset_loader <- arrow::open_dataset
  }

  # ── 5. Group vars by (path, hex_col) → one fetch per source ─────────
  source_groups <- hex_split_by_source(vars)

  # ── 6. Fetch each source ─────────────────────────────────────────────
  cli::cli_progress_step(
    "Fetching {length(source_groups)} source{?s} for \\
{length(hex_ids)} cell{?s}..."
  )

  result_parts <- lapply(source_groups, function(grp) {
    hex_fetch_source(grp, fetch_ids, dataset_loader)
  })

  cli::cli_progress_done()

  # ── 7. Join all source parts on hex_id ──────────────────────────────
  hex_tbl <- Reduce(
    function(a, b) dplyr::left_join(a, b, by = "hex_id"),
    result_parts
  )

  # ── 8. Bridge: aggregate H6 → H5 ────────────────────────────────────
  if (use_bridge) {
    hex_tbl <- hex_bridge_aggregate(hex_tbl, parent_map, vars)
  }

  # ── 9. Reorder: population always first after hex_id ────────────────
  pop_col <- hex_find_population_col(vars, names(hex_tbl))
  if (!is.null(pop_col)) {
    other_cols <- setdiff(names(hex_tbl), c("hex_id", pop_col))
    hex_tbl    <- hex_tbl[, c("hex_id", pop_col, other_cols)]
  }

  tibble::as_tibble(hex_tbl)
}


# ── Internal helpers ─────────────────────────────────────────────────────────

# Robust downloader for hex parquet sources. The WB Data Catalog
# (`datacatalogfiles.worldbank.org`, Azure blob storage) drops large
# transfers mid-stream, so a single `download.file()` call truncates.
# This shells out to `curl` with `-C -` (resume from the partial file)
# and `--retry`/`--retry-all-errors` (retry the dropped streams); a
# browser User-Agent is required because the endpoint 403s the default
# `curl/x.y` agent. See issue #190.
hex_curl_download <- function(url, destfile, mode = "wb", quiet = TRUE) {
  utils::download.file(
    url, destfile,
    mode   = mode,
    quiet  = quiet,
    method = "curl",
    extra  = c(
      "-fsSL",                 # fail on HTTP errors, follow redirects, silent
      "-C", "-",               # resume from whatever is already on disk
      "--retry", "8",          # retry dropped/transient transfers
      "--retry-all-errors",    # treat mid-stream drops as retryable
      "-A", "Mozilla/5.0"      # endpoint 403s the default curl/ user-agent
    )
  )
}

# Resolve a registry source path to something `arrow::open_dataset()` can
# open. arrow's `FileSystem$from_uri()` recognises `s3://`, `gs://`,
# `file://`, `hdfs://`, etc. — but **not** plain `http://` / `https://`.
# When the registry path is an HTTP(S) URL we download it to a local
# tempfile first; everything else passes through unchanged. The
# `downloader` seam exists for tests; the default is the retry+resume
# `hex_curl_download()` (issue #190).
hex_resolve_path <- function(path, downloader = hex_curl_download) {
  if (is.character(path) &&
        length(path) == 1L &&
        (startsWith(path, "http://") || startsWith(path, "https://"))) {
    tmp <- tempfile(fileext = ".parquet")
    downloader(path, tmp, mode = "wb", quiet = TRUE)
    return(tmp)
  }
  path
}


# Group a vars list by (backend, source root, hex_col).
hex_split_by_source <- function(vars) {
  keys <- vapply(vars, function(v) {
    backend <- v$backend %||% "parquet"
    root    <- if (identical(backend, "rest")) v$api_root %||% ""
               else v$path %||% ""
    paste0(backend, "|||", root, "|||", v$hex_col)
  }, character(1L))
  lapply(unique(keys), function(k) {
    grp_vars <- vars[keys == k]
    v1 <- grp_vars[[1L]]
    list(
      backend  = v1$backend %||% "parquet",
      path     = v1$path,
      api_root = v1$api_root %||% NA_character_,
      hex_col  = v1$hex_col,
      vars     = grp_vars
    )
  })
}


# Fetch one parquet source and return a wide tibble keyed by hex_id.
hex_fetch_source <- function(grp, fetch_ids, dataset_loader) {
  if (identical(grp$backend, "rest")) {
    return(hex_fetch_source_rest(grp, fetch_ids))
  }

  path    <- grp$path
  hex_col <- grp$hex_col
  gvars   <- grp$vars

  static_vars   <- Filter(function(v) is.na(v$time_col), gvars)
  temporal_vars <- Filter(function(v) !is.na(v$time_col), gvars)

  # Columns to pull from the parquet.
  static_src_cols   <- vapply(static_vars, `[[`, character(1L), "source_col")
  temporal_src_cols <- unique(vapply(temporal_vars, `[[`, character(1L), "source_col"))
  time_cols         <- unique(vapply(temporal_vars, `[[`, character(1L), "time_col"))

  select_cols <- unique(c(hex_col, static_src_cols, time_cols, temporal_src_cols))

  # Collect from parquet (or mock in tests). HTTP(S) paths are
  # downloaded to a local tempfile first so arrow can open them.
  ds  <- dataset_loader(hex_resolve_path(path))
  raw <- ds |>
    dplyr::filter(.data[[hex_col]] %in% fetch_ids) |>
    dplyr::select(dplyr::all_of(select_cols)) |>
    dplyr::collect()

  # Rename hex column → "hex_id".
  if (hex_col != "hex_id") {
    names(raw)[names(raw) == hex_col] <- "hex_id"
  }

  # Non-temporal: rename source_col → canonical_name.
  for (v in static_vars) {
    if (v$source_col %in% names(raw) && v$source_col != v$canonical_name) {
      names(raw)[names(raw) == v$source_col] <- v$canonical_name
    }
  }

  # Temporal: filter to resolved years, pivot wide per variable.
  if (length(temporal_vars) > 0L) {
    tc <- time_cols[[1L]]  # one time column per source is the norm

    for (v in temporal_vars) {
      if (length(v$years) == 0L) next
      var_long <- raw[raw[[tc]] %in% v$years,
                      c("hex_id", tc, v$source_col),
                      drop = FALSE]
      names(var_long)[names(var_long) == v$source_col] <- ".value"

      var_wide <- tidyr::pivot_wider(
        var_long,
        id_cols     = "hex_id",
        names_from  = tc,
        values_from = ".value",
        names_glue  = paste0(v$canonical_name, "_{", tc, "}")
      )
      raw <- dplyr::left_join(raw, var_wide, by = "hex_id")
    }

    # Drop the raw long columns.
    drop <- c(time_cols, temporal_src_cols)
    raw  <- raw[, setdiff(names(raw), drop), drop = FALSE]
  }

  raw
}


hex_fetch_source_rest <- function(grp, fetch_ids) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg httr2} is required for REST hex sources.",
      "i" = "Install it with {.run install.packages('httr2')}."
    ))
  }
  api_root <- grp$api_root
  hex_col  <- grp$hex_col
  gvars    <- grp$vars
  field_map <- list()
  for (v in gvars) {
    if (length(v$resolved_cols) > 0L) {
      tmpl   <- v$source_col_template
      prefix <- sub("\\{year\\}.*", "", tmpl)
      for (rc in v$resolved_cols) {
        year_str <- sub(paste0("^", prefix), "", rc)
        out_col  <- paste0(v$canonical_name, "_", year_str)
        field_map[[rc]] <- out_col
      }
    } else if (!is.na(v$source_col)) {
      field_map[[v$source_col]] <- v$canonical_name
    }
  }
  all_fields <- names(field_map)
  chunk_size <- 5000L
  n          <- length(fetch_ids)
  chunks     <- split(fetch_ids, ceiling(seq_len(n) / chunk_size))
  pages <- lapply(chunks, function(batch) {
    body <- list(hex_ids = batch, fields = all_fields)
    resp <- httr2::req_perform(
      httr2::req_body_json(
        httr2::request(paste0(api_root, "/summary_by_hexids")),
        body
      )
    )
    result <- httr2::resp_body_json(resp, simplifyVector = TRUE)
    if (!is.data.frame(result)) result <- as.data.frame(result)
    result
  })
  raw <- do.call(rbind, pages)
  if (hex_col != "hex_id" && hex_col %in% names(raw)) {
    names(raw)[names(raw) == hex_col] <- "hex_id"
  }
  for (src_col in names(field_map)) {
    out_col <- field_map[[src_col]]
    if (src_col %in% names(raw) && src_col != out_col) {
      names(raw)[names(raw) == src_col] <- out_col
    }
  }
  keep <- c("hex_id", unname(unlist(field_map)))
  raw[, intersect(keep, names(raw)), drop = FALSE]
}


# Aggregate H6 tibble back to H5 using each variable's weight/fun.
hex_bridge_aggregate <- function(h6_data, parent_map, vars) {
  merged <- dplyr::left_join(
    h6_data,
    parent_map,
    by = c("hex_id" = "hex_id_child")
  )

  pop_col <- hex_find_population_col(vars, names(h6_data))

  data_cols <- setdiff(names(h6_data), "hex_id")
  grouped   <- dplyr::group_by(merged, hex_id = .data$hex_id_parent)

  agg_exprs <- lapply(data_cols, function(col) {
    # Match column to its variable descriptor.
    v <- hex_var_for_col(col, vars)
    weight <- if (is.null(v)) "none" else v$weight
    fun    <- if (is.null(v)) "mean" else v$fun
    is_pop <- !is.null(v) && isTRUE(v$internal)

    if (is_pop || fun == "sum" && weight == "none") {
      # Population (and "sum, no weight") → additive.
      bquote(sum(.data[[.(col)]], na.rm = TRUE))
    } else if (weight == "pop" && !is.null(pop_col)) {
      # Population-weighted mean (used for rates/densities).
      bquote(
        if (all(is.na(.data[[.(col)]]))) NA_real_
        else {
          w <- .data[[.(pop_col)]]; w[is.na(w)] <- 0
          stats::weighted.mean(.data[[.(col)]], w, na.rm = TRUE)
        }
      )
    } else {
      # Unweighted (weight="none" or weight="area", which is uniform).
      switch(fun,
        "mean"   = bquote(mean(.data[[.(col)]], na.rm = TRUE)),
        "sum"    = bquote(sum(.data[[.(col)]], na.rm = TRUE)),
        "min"    = bquote(min(.data[[.(col)]], na.rm = TRUE)),
        "max"    = bquote(max(.data[[.(col)]], na.rm = TRUE)),
        "median" = bquote(stats::median(.data[[.(col)]], na.rm = TRUE)),
        bquote(mean(.data[[.(col)]], na.rm = TRUE))
      )
    }
  })
  names(agg_exprs) <- data_cols

  result <- dplyr::summarise(grouped, !!!agg_exprs, .groups = "drop")
  tibble::as_tibble(result)
}


# Find the output column name for the population variable.
hex_find_population_col <- function(vars, col_names) {
  pop_vars <- Filter(function(v) isTRUE(v$internal), vars)
  if (length(pop_vars) == 0L) return(NULL)
  pop_canon <- pop_vars[[1L]]$canonical_name
  if (pop_canon %in% col_names) pop_canon else NULL
}


# Find the pti_hex_var whose output canonical_name (or temporal
# <canonical>_<year> suffix) matches a given output column.
hex_var_for_col <- function(col, vars) {
  # Exact canonical match (non-temporal).
  direct <- vars[vapply(vars, function(v) identical(v$canonical_name, col),
                        logical(1L))]
  if (length(direct) > 0L) return(direct[[1L]])

  # Temporal: strip _<year> suffix and try canonical match.
  stem <- sub("_[0-9]{4}$", "", col)
  if (stem != col) {
    stem_match <- vars[vapply(vars, function(v) identical(v$canonical_name, stem),
                              logical(1L))]
    if (length(stem_match) > 0L) return(stem_match[[1L]])
  }

  NULL
}
