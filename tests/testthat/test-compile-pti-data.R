# Tests for compile_pti_data() — issue #83.
#
# Coverage map (vs issue #83 acceptance criteria):
#
# 1. Single metadata input → both outputs produced.
# 2. Multiple metadata inputs → merged correctly (metadata rows union; admin
#    sheets full-joined; duplicates flagged).
# 3. Validates combined inputs → returns list(status, summary, issues).
# 4. error_on_fail = TRUE throws on validation failure.
# 5. error_on_fail = FALSE returns structured result on failure.
# 6. Output `metadata.xlsx` readable by fct_template_reader().
# 7. Output `shapefiles.zip` contains GeoJSON files (one per admin level).
# 8. Verbose CLI output — emits the expected counts.
# 9. Defensive input gate (missing / NULL / non-string / non-existent).

# ---------------------------------------------------------------------------
# Helpers — write the bundled Ukraine fixtures to disk so we can test
# the path-based contract.

.write_ukr_inputs <- function(dir, mtdt_filename = "metadata-user.xlsx") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  shp_path  <- file.path(dir, "shapes.rds")
  mtdt_path <- file.path(dir, mtdt_filename)
  saveRDS(ukr_shp, shp_path)

  # Write only the parts that came from the source xlsx (not the
  # internal `weights_clean` field added by fct_template_reader).
  to_write <- ukr_mtdt_full
  to_write$weights_clean <- NULL
  writexl::write_xlsx(to_write, path = mtdt_path)

  list(shp_path = shp_path, mtdt_path = mtdt_path)
}

# ---------------------------------------------------------------------------
# 1) Single-input happy path

test_that("compile_pti_data: single input produces all expected artefacts", {
  tmp <- tempfile("compile-single-")
  paths <- .write_ukr_inputs(tmp)

  res <- suppressMessages(suppressWarnings(compile_pti_data(
    shp_path       = paths$shp_path,
    metadata_paths = paths$mtdt_path,
    output_dir     = tmp,
    error_on_fail  = FALSE
  )))

  expect_true(file.exists(file.path(tmp, "metadata.xlsx")))
  expect_true(file.exists(file.path(tmp, "shapefiles.zip")))
  expect_setequal(
    names(res),
    c("status", "summary", "issues",
      "metadata_path", "shapefiles_path")
  )
  expect_true(res$status %in% c("pass", "warn", "fail"))
})

# ---------------------------------------------------------------------------
# 2) Output xlsx readable by fct_template_reader (round-trip)

test_that("compile_pti_data: output metadata.xlsx is readable by fct_template_reader", {
  tmp <- tempfile("compile-roundtrip-")
  paths <- .write_ukr_inputs(tmp)
  suppressMessages(suppressWarnings(compile_pti_data(
    paths$shp_path, paths$mtdt_path, tmp, error_on_fail = FALSE
  )))

  re_read <- fct_template_reader(file.path(tmp, "metadata.xlsx"))
  expect_true("metadata" %in% names(re_read))
  expect_true("general"  %in% names(re_read))
  expect_true(NROW(re_read$metadata) >= NROW(ukr_mtdt_full$metadata))
})

# ---------------------------------------------------------------------------
# 3) Output zip contains one GeoJSON per admin layer

test_that("compile_pti_data: shapefiles.zip contains one GeoJSON per admin layer", {
  tmp <- tempfile("compile-zip-")
  paths <- .write_ukr_inputs(tmp)
  suppressMessages(suppressWarnings(compile_pti_data(
    paths$shp_path, paths$mtdt_path, tmp, error_on_fail = FALSE
  )))

  zip_path <- file.path(tmp, "shapefiles.zip")
  zip_contents <- zip::zip_list(zip_path)$filename
  geojson_files <- grep("\\.geojson$", zip_contents, value = TRUE)

  expect_equal(length(geojson_files), length(ukr_shp))
  for (slot in names(ukr_shp)) {
    expect_true(any(grepl(paste0("^", slot, "\\.geojson$"), basename(geojson_files))),
                info = paste("missing GeoJSON for slot:", slot))
  }
})

# ---------------------------------------------------------------------------
# 4) Multi-input merge — split ukr_mtdt_full into two halves and verify the
#    merge re-combines them.

test_that("compile_pti_data: multi-input merge unions metadata rows", {
  tmp <- tempfile("compile-multi-")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)

  # Build two split inputs whose metadata sheets are disjoint by var_code.
  full <- ukr_mtdt_full
  full$weights_clean <- NULL
  half_idx <- seq_len(floor(NROW(full$metadata) / 2))

  side_a <- full
  side_a$metadata <- full$metadata[half_idx, , drop = FALSE]
  side_a$weights_table <- NULL  # avoid duplicate-weights warning

  side_b <- full
  side_b$metadata <- full$metadata[-half_idx, , drop = FALSE]
  side_b$weights_table <- NULL

  shp_path  <- file.path(tmp, "shapes.rds")
  saveRDS(ukr_shp, shp_path)
  a_path <- file.path(tmp, "metadata-user.xlsx")
  b_path <- file.path(tmp, "metadata-hex.xlsx")
  writexl::write_xlsx(side_a, path = a_path)
  writexl::write_xlsx(side_b, path = b_path)

  res <- suppressMessages(suppressWarnings(compile_pti_data(
    shp_path       = shp_path,
    metadata_paths = c(a_path, b_path),
    output_dir     = tmp,
    error_on_fail  = FALSE
  )))

  re_read <- fct_template_reader(file.path(tmp, "metadata.xlsx"))
  # Should recover the full var_code set.
  expect_setequal(re_read$metadata$var_code, full$metadata$var_code)
})

# ---------------------------------------------------------------------------
# 5) Defensive input gate

test_that("compile_pti_data: errors on missing / non-existent / non-character paths", {
  tmp <- tempfile("compile-gate-"); dir.create(tmp, recursive = TRUE)
  paths <- .write_ukr_inputs(tmp)

  expect_error(compile_pti_data(metadata_paths = paths$mtdt_path,
                                output_dir = tmp),
               regexp = "shp_path")
  expect_error(compile_pti_data(shp_path = paths$shp_path,
                                output_dir = tmp),
               regexp = "metadata_paths")
  expect_error(compile_pti_data(paths$shp_path, paths$mtdt_path),
               regexp = "output_dir")
  expect_error(compile_pti_data("/no/such/file.rds", paths$mtdt_path, tmp),
               regexp = "does not exist")
  expect_error(compile_pti_data(paths$shp_path, "/no/such/x.xlsx", tmp),
               regexp = "does not exist")
})

# ---------------------------------------------------------------------------
# 6) error_on_fail behaviour

test_that("compile_pti_data: error_on_fail = FALSE returns structured result on failure", {
  tmp <- tempfile("compile-fail-"); dir.create(tmp, recursive = TRUE)

  # Force a failure by stripping the admin1Pcod column from the layer.
  broken_shp <- ukr_shp
  broken_shp$admin1_Oblast$admin1Pcod <- NULL
  shp_path  <- file.path(tmp, "shapes.rds")
  mtdt_path <- file.path(tmp, "metadata-user.xlsx")
  saveRDS(broken_shp, shp_path)

  to_write <- ukr_mtdt_full
  to_write$weights_clean <- NULL
  writexl::write_xlsx(to_write, path = mtdt_path)

  res <- suppressMessages(suppressWarnings(compile_pti_data(
    shp_path       = shp_path,
    metadata_paths = mtdt_path,
    output_dir     = tmp,
    error_on_fail  = FALSE
  )))
  expect_equal(res$status, "fail")
  expect_true(length(res$issues) > 0)
})

test_that("compile_pti_data: error_on_fail = TRUE throws on failure", {
  tmp <- tempfile("compile-fail-throw-"); dir.create(tmp, recursive = TRUE)

  broken_shp <- ukr_shp
  broken_shp$admin1_Oblast$admin1Pcod <- NULL
  shp_path  <- file.path(tmp, "shapes.rds")
  mtdt_path <- file.path(tmp, "metadata-user.xlsx")
  saveRDS(broken_shp, shp_path)

  to_write <- ukr_mtdt_full
  to_write$weights_clean <- NULL
  writexl::write_xlsx(to_write, path = mtdt_path)

  expect_error(
    suppressMessages(suppressWarnings(compile_pti_data(
      shp_path, mtdt_path, tmp, error_on_fail = TRUE
    ))),
    regexp = "validation failed"
  )
})

# ---------------------------------------------------------------------------
# 7) CLI summary — emits the expected counts

test_that("compile_pti_data: structured summary carries layer / polygon / indicator counts", {
  # The CLI summary is an end-user nicety, but the structured
  # `result$summary` field is the part downstream code (and the
  # PR-wide r-package-reviewer convention) actually reads. Asserting
  # on the structured return covers the same generator code path
  # without depending on the `cli` backend's sink choice.
  tmp <- tempfile("compile-summary-"); dir.create(tmp, recursive = TRUE)
  paths <- .write_ukr_inputs(tmp)

  res <- suppressMessages(suppressWarnings(compile_pti_data(
    paths$shp_path, paths$mtdt_path, tmp, error_on_fail = FALSE
  )))

  expect_type(res$summary, "character")
  expect_match(res$summary, "Layers", all = FALSE)
  expect_match(res$summary, "Polygons", all = FALSE)
  expect_match(res$summary, "Indicators", all = FALSE)
  expect_match(res$summary, paste0("Layers: ", length(ukr_shp)), all = FALSE)
})

# ---------------------------------------------------------------------------
# Tests for compile_merge_metadata() — issue #117 acceptance criteria
# (uses the internal function directly; all scenarios below exercise
#  the merge contract without full file I/O).

.make_parsed <- function(var_code, var_name, country = "Test",
                         adm_col = NULL, weights_tbl = NULL) {
  col <- if (is.null(adm_col)) var_code else adm_col
  list(
    general  = tibble::tibble(country = country),
    metadata = tibble::tibble(var_code = var_code, var_name = var_name),
    admin1_Province = tibble::tibble(
      admin1Pcod = c("P1", "P2"),
      admin1Name = c("N1", "N2"),
      year       = NA_character_,
      !!col      := c(1.0, 2.0)
    ),
    weights_table = weights_tbl
  )
}

# 9) Duplicate var_code across inputs -> both rows kept with __<source> suffix

test_that("compile_merge_metadata: duplicate var_code gets __source suffix", {
  pa <- .make_parsed("pov", "Poverty A")
  pb <- .make_parsed("pov", "Poverty B")

  expect_warning(
    result <- compile_merge_metadata(list(pa, pb), c("user", "hex")),
    regexp = "Duplicate"
  )

  expect_true("pov__user" %in% result$metadata$var_code)
  expect_true("pov__hex"  %in% result$metadata$var_code)
  expect_equal(NROW(result$metadata), 2L)
})

# 10) Admin column renamed to match var_code rename

test_that("compile_merge_metadata: admin column renamed in sync with var_code", {
  pa <- .make_parsed("pov", "Poverty A")
  pb <- .make_parsed("pov", "Poverty B")

  suppressWarnings(
    result <- compile_merge_metadata(list(pa, pb), c("user", "hex"))
  )

  adm <- result$admin1_Province
  expect_true("pov__user" %in% names(adm))
  expect_true("pov__hex"  %in% names(adm))
  expect_false("pov"      %in% names(adm))
})

# 11) general sheet: first file wins

test_that("compile_merge_metadata: general sheet is taken from first input", {
  pa <- .make_parsed("ind_a", "Indicator A", country = "Alpha")
  pb <- .make_parsed("ind_b", "Indicator B", country = "Beta")

  result <- compile_merge_metadata(list(pa, pb), c("user", "hex"))
  expect_equal(result$general$country[[1L]], "Alpha")
})

# 12) weights_table: first non-empty wins; warning if multiple

test_that("compile_merge_metadata: weights_table first-non-empty wins, warns on multiple", {
  wt <- tibble::tibble(admin_level = "admin1", weight = 1L)
  pa <- .make_parsed("ind_a", "A", weights_tbl = wt)
  pb <- .make_parsed("ind_b", "B", weights_tbl = wt)

  expect_warning(
    result <- compile_merge_metadata(list(pa, pb), c("user", "hex")),
    regexp = "weights_table"
  )
  expect_equal(result$weights_table, wt)
})

# 13) .x/.y suffix detection warns when a non-key non-renamed column overlaps

test_that("compile_merge_metadata: .x/.y columns trigger a warning", {
  pa <- .make_parsed("ind_a", "A", adm_col = "ind_a")
  pb <- .make_parsed("ind_b", "B", adm_col = "ind_b")
  # Both admin sheets have a shared non-key, non-indicator column; it
  # will survive as extra.x / extra.y after full_join.
  pa$admin1_Province$extra <- 9L
  pb$admin1_Province$extra <- 7L

  expect_warning(
    compile_merge_metadata(list(pa, pb), c("user", "hex")),
    regexp = "\\.x|\\.y|mismatch"
  )
})

# ---------------------------------------------------------------------------
# var_overrides argument (arch-13 §G / issue #158)

test_that("compile_pti_data: var_overrides flips fltr_exclude flags on matched rows", {
  tmp <- tempfile("compile-vo-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(
    canonical_name = "var_nval3_skewd_adm1",
    in_pti         = FALSE,
    in_explorer    = TRUE
  )
  compile_pti_data(
    shp_path       = paths$shp_path,
    metadata_paths = paths$mtdt_path,
    output_dir     = tmp,
    error_on_fail  = FALSE,
    var_overrides  = vo
  )
  m <- fct_template_reader(file.path(tmp, "metadata.xlsx"))$metadata
  row <- m[m$var_code == "var_nval3_skewd_adm1", ]
  expect_true(row$fltr_exclude_pti)        # in_pti = FALSE  -> excluded
  expect_false(row$fltr_exclude_explorer)  # in_explorer = TRUE -> kept
  other <- m[m$var_code == "var_nval6_na_adm12", ]
  expect_false(other$fltr_exclude_pti)     # untouched row keeps its default
})

test_that("compile_pti_data: var_overrides NA cell leaves that one flag unchanged", {
  tmp <- tempfile("compile-vo-na-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(
    canonical_name = "var_nval3_skewd_adm1",
    in_pti         = NA,
    in_explorer    = FALSE
  )
  compile_pti_data(
    shp_path = paths$shp_path, metadata_paths = paths$mtdt_path,
    output_dir = tmp, error_on_fail = FALSE, var_overrides = vo
  )
  m <- fct_template_reader(file.path(tmp, "metadata.xlsx"))$metadata
  row <- m[m$var_code == "var_nval3_skewd_adm1", ]
  expect_false(row$fltr_exclude_pti)       # in_pti = NA -> unchanged (default)
  expect_true(row$fltr_exclude_explorer)   # in_explorer = FALSE -> excluded
})

test_that("compile_pti_data: var_overrides warns and skips an unmatched canonical_name", {
  tmp <- tempfile("compile-vo-unmatched-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(
    canonical_name = "no_such_variable",
    in_pti         = FALSE,
    in_explorer    = FALSE
  )
  expect_warning(
    compile_pti_data(
      shp_path = paths$shp_path, metadata_paths = paths$mtdt_path,
      output_dir = tmp, error_on_fail = FALSE, var_overrides = vo
    ),
    regexp = "no_such_variable"
  )
})

test_that("compile_pti_data: var_overrides must be a data frame or NULL", {
  tmp <- tempfile("compile-vo-err1-")
  paths <- .write_ukr_inputs(tmp)
  expect_error(
    compile_pti_data(paths$shp_path, paths$mtdt_path, tmp,
                     var_overrides = c("a", "b")),
    regexp = "var_overrides.*data frame"
  )
})

test_that("compile_pti_data: var_overrides missing a required column errors", {
  tmp <- tempfile("compile-vo-err2-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(canonical_name = "x", in_pti = TRUE)
  expect_error(
    compile_pti_data(paths$shp_path, paths$mtdt_path, tmp, var_overrides = vo),
    regexp = "var_overrides.*column"
  )
})

test_that("compile_pti_data: var_overrides non-logical flag column errors", {
  tmp <- tempfile("compile-vo-err3-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(canonical_name = "x", in_pti = "yes", in_explorer = TRUE)
  expect_error(
    compile_pti_data(paths$shp_path, paths$mtdt_path, tmp, var_overrides = vo),
    regexp = "logical"
  )
})

test_that("compile_pti_data: var_overrides duplicate canonical_name errors", {
  tmp <- tempfile("compile-vo-err4-")
  paths <- .write_ukr_inputs(tmp)
  vo <- tibble::tibble(
    canonical_name = c("dup", "dup"),
    in_pti         = c(TRUE, FALSE),
    in_explorer    = c(TRUE, TRUE)
  )
  expect_error(
    compile_pti_data(paths$shp_path, paths$mtdt_path, tmp, var_overrides = vo),
    regexp = "duplicate"
  )
})
