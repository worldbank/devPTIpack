#' Plot administrative boundary layers by level
#'
#' Creates a faceted `ggplot2` map from a named list of `sf` layers, with one
#' panel for each administrative level and an optional highlighted level.
#'
#' @param shp_dta A named list of `sf` objects, one per administrative level.
#' @param highlight_level Optional character scalar naming the level in
#'   `shp_dta` to fill with the highlight colour.
#'
#' @return A `ggplot` object with one facet per administrative level.
#' @family pti-report
#' @importFrom ggplot2 ggplot aes geom_sf facet_wrap scale_fill_manual theme_void
#' @importFrom cli cli_abort
#' @importFrom purrr imap
#' @importFrom dplyr bind_rows mutate select
#' @importFrom rlang .data
#' @importFrom sf st_as_sf
#' @export
#'
#' @examples
#' data(ukr_shp)
#' pti_plot_boundaries(ukr_shp)
#' pti_plot_boundaries(ukr_shp, highlight_level = "admin1_Oblast")
pti_plot_boundaries <- function(shp_dta, highlight_level = NULL) {
  is_sf <- vapply(shp_dta, inherits, logical(1), what = "sf")
  if (!all(is_sf)) {
    cli::cli_abort("Every element of {.arg shp_dta} must inherit from {.cls sf}.")
  }

  if (!is.null(highlight_level) && !highlight_level %in% names(shp_dta)) {
    cli::cli_abort("{.arg highlight_level} must be one of {.code names(shp_dta)}.")
  }

  combined <- shp_dta |>
    purrr::imap(function(layer, slot_name) {
      layer |>
        sf::st_as_sf() |>
        dplyr::mutate(
          .label = paste0(slot_name, " (", nrow(layer), " polygons)"),
          .is_highlighted = !is.null(highlight_level) && slot_name == highlight_level
        ) |>
        dplyr::select("geometry", ".label", ".is_highlighted")
    }) |>
    dplyr::bind_rows()

  ggplot2::ggplot(combined) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data[[".is_highlighted"]]),
      colour = "grey40",
      linewidth = 0.15
    ) +
    ggplot2::facet_wrap(~.label) +
    ggplot2::scale_fill_manual(
      values = c("FALSE" = "grey85", "TRUE" = "#E86C2C"),
      guide = "none"
    ) +
    ggplot2::theme_void()
}

#' Plot a histogram for a PTI variable
#'
#' Builds a histogram for a named variable in a data frame or `sf` object, with
#' optional dashed vertical lines marking requested percentiles.
#'
#' @param data A data frame, tibble, or `sf` object containing `var`.
#' @param var Character scalar naming the column to plot.
#' @param bins Number of histogram bins to draw.
#' @param percentiles Numeric vector of probabilities passed to
#'   [stats::quantile()], or `NULL` to omit percentile lines.
#'
#' @return A `ggplot` histogram object.
#' @family pti-report
#' @importFrom ggplot2 ggplot aes geom_histogram geom_vline theme_minimal labs
#' @importFrom cli cli_abort
#' @importFrom rlang .data
#' @importFrom sf st_drop_geometry
#' @importFrom stats quantile
#' @export
#'
#' @examples
#' data(ukr_mtdt_full)
#' pti_plot_histogram(ukr_mtdt_full$admin1_Oblast, "var_nval3_skewd_adm1")
#' pti_plot_histogram(
#'   ukr_mtdt_full$admin1_Oblast,
#'   "var_nval3_skewd_adm1",
#'   percentiles = NULL
#' )
pti_plot_histogram <- function(data, var, bins = 30,
                               percentiles = c(0.1, 0.25, 0.5, 0.75, 0.9)) {
  if (!var %in% names(data)) {
    cli::cli_abort("{.arg var} must name a column in {.arg data}.")
  }

  if (inherits(data, "sf")) {
    data <- sf::st_drop_geometry(data)
  }

  vals <- data[[var]]

  base <- ggplot2::ggplot(data.frame(x = vals), ggplot2::aes(x = .data[["x"]])) +
    ggplot2::geom_histogram(bins = bins) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = var, y = "count")

  if (!is.null(percentiles)) {
    quants <- stats::quantile(vals, probs = percentiles, na.rm = TRUE)
    for (quant in quants) {
      base <- base +
        ggplot2::geom_vline(
          xintercept = quant,
          colour = "#E86C2C",
          linetype = "dashed"
        )
    }
  }

  base
}

#' Summarise PTI variables in a reactable table
#'
#' Creates a `reactable` widget that summarises either compiled PTI metadata by
#' variable or hex-level variable coverage for a hex data table.
#'
#' @param compiled_data For `type = "overview"`, a named list returned by
#'   [fct_template_reader()] with a `metadata` tibble and admin-level tibbles.
#'   For `type = "hex"`, a tibble with a `hex_id` column and variable columns.
#' @param type Character scalar selecting the summary table type: `"overview"`
#'   or `"hex"`.
#'
#' @return A `reactable` htmlwidget.
#' @family pti-report
#' @importFrom rlang check_installed
#' @importFrom dplyr mutate
#' @importFrom tibble tibble
#' @importFrom jsonlite toJSON
#' @importFrom stats quantile sd median
#' @export
#'
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   data(ukr_mtdt_full)
#'   pti_summary_table(ukr_mtdt_full, type = "overview")
#'
#'   hex_data <- tibble::tibble(
#'     hex_id  = paste0("hex_", 1:4),
#'     poverty = c(0.2, NA, 0.4, NA)
#'   )
#'   pti_summary_table(hex_data, type = "hex")
#' }
pti_summary_table <- function(compiled_data, type = c("overview", "hex")) {
  type <- match.arg(type)
  rlang::check_installed("reactable")

  if (type == "overview") {
    summary_tbl <- build_pti_overview_summary(compiled_data)
    return(pti_reactable(summary_tbl, groupBy = "pillar_name"))
  }

  var_cols <- setdiff(names(compiled_data), "hex_id")
  summary_tbl <- tibble::tibble(
    var_name = var_cols,
    non_missing_count = vapply(
      var_cols,
      function(col) sum(!is.na(compiled_data[[col]])),
      integer(1)
    ),
    coverage_pct = vapply(
      var_cols,
      function(col) {
        non_missing <- sum(!is.na(compiled_data[[col]]))
        round(100 * non_missing / nrow(compiled_data), 1)
      },
      numeric(1)
    )
  )

  pti_reactable(summary_tbl)
}

#' @noRd
build_pti_overview_summary <- function(compiled_data) {
  rows <- lapply(seq_len(nrow(compiled_data$metadata)), function(i) {
    row <- compiled_data$metadata[i, , drop = FALSE]
    vals <- as.numeric(compiled_data[[row$spatial_level]][[row$var_code]])
    quants <- stats::quantile(
      vals,
      probs = c(q10 = 0.1, q25 = 0.25, q75 = 0.75, q90 = 0.9),
      na.rm = TRUE
    )

    tibble::tibble(
      var_name = row$var_name,
      pillar_name = row$pillar_name,
      spatial_level = row$spatial_level,
      fltr_exclude_pti = row$fltr_exclude_pti,
      fltr_exclude_explorer = row$fltr_exclude_explorer,
      min = min(vals, na.rm = TRUE),
      q10 = unname(quants[[1]]),
      q25 = unname(quants[[2]]),
      median = stats::median(vals, na.rm = TRUE),
      mean = mean(vals, na.rm = TRUE),
      q75 = unname(quants[[3]]),
      q90 = unname(quants[[4]]),
      max = max(vals, na.rm = TRUE),
      sd = stats::sd(vals, na.rm = TRUE)
    )
  })

  dplyr::bind_rows(rows)
}

#' @noRd
pti_reactable <- function(summary_tbl, ...) {
  widget <- reactable::reactable(summary_tbl, ...)
  widget$x$tag$attribs$data <- jsonlite::toJSON(
    summary_tbl,
    dataframe = "rows",
    rownames = FALSE,
    digits = NA,
    POSIXt = "ISO8601",
    Date = "ISO8601",
    UTC = TRUE,
    force = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null"
  )
  widget
}

#' Plot a choropleth map for a PTI variable
#'
#' Builds a `ggplot2` choropleth from a single `sf` object, mapping a named
#' numeric column to polygon fill without joining or transforming the input.
#'
#' @param data An `sf` object containing `var` and a geometry column.
#' @param var Character scalar naming the numeric column to map as polygon fill.
#'
#' @return A `ggplot` choropleth object.
#' @family pti-report
#' @importFrom ggplot2 ggplot aes geom_sf scale_fill_gradient theme_void
#' @importFrom cli cli_abort
#' @importFrom rlang .data
#' @export
#'
#' @examples
#' data(ukr_shp)
#' pti_plot_choropleth(ukr_shp$admin1_Oblast, "area")
pti_plot_choropleth <- function(data, var) {
  if (!inherits(data, "sf")) {
    cli::cli_abort("{.arg data} must be an {.cls sf} object.")
  }

  if (!is.character(var) || length(var) != 1L || is.na(var)) {
    cli::cli_abort("{.arg var} must be a character scalar.")
  }

  if (!var %in% names(data)) {
    cli::cli_abort("{.arg var} must name a column in {.arg data}.")
  }

  if (!is.numeric(data[[var]])) {
    cli::cli_abort("{.arg var} must name a numeric column.")
  }

  if (nrow(data) == 0L) {
    cli::cli_abort("{.arg data} must contain at least one row.")
  }

  ggplot2::ggplot(data) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data[[var]]),
      colour = "grey40",
      linewidth = 0.15
    ) +
    ggplot2::scale_fill_gradient(
      name = var,
      low = "grey90",
      high = "#E86C2C",
      na.value = "grey85"
    ) +
    ggplot2::theme_void()
}
