# Tier-1 tests for fct_pti_report_helpers.R (arch-13 §C / issue #151).
# Three exported helpers: pti_plot_boundaries(), pti_plot_histogram(),
# pti_summary_table().
#
# Contracts (agreed 2026-05-17):
#   pti_plot_boundaries()  → single ggplot, one facet per admin level;
#                            highlight_level fills that level in accent colour.
#   pti_plot_histogram()   → ggplot histogram + geom_vline per percentile;
#                            var passed as character string.
#   pti_summary_table()    → reactable htmlwidget;
#     type="overview"      compiled_data = fct_template_reader() output
#                          (named list with $metadata + admin-level tibbles);
#     type="hex"           compiled_data = hex_data tibble from
#                          fetch_hex_data() (rows = hex cells, cols = vars).

# ---------------------------------------------------------------------------
# pti_plot_boundaries()
# ---------------------------------------------------------------------------

test_that("pti_plot_boundaries: returns a ggplot object", {
  data(ukr_shp, package = "devPTIpack")
  result <- pti_plot_boundaries(ukr_shp)
  expect_s3_class(result, "gg")
})

test_that("pti_plot_boundaries: plot has one panel per admin level", {
  data(ukr_shp, package = "devPTIpack")
  result <- pti_plot_boundaries(ukr_shp)
  layout <- ggplot2::ggplot_build(result)$layout$layout
  expect_equal(nrow(layout), length(ukr_shp))
})

test_that("pti_plot_boundaries: highlight_level does not error and returns gg", {
  data(ukr_shp, package = "devPTIpack")
  result <- pti_plot_boundaries(ukr_shp, highlight_level = "admin1_Oblast")
  expect_s3_class(result, "gg")
})

test_that("pti_plot_boundaries: non-sf element in shp_dta produces cli_abort", {
  data(ukr_shp, package = "devPTIpack")
  bad_shp <- ukr_shp
  bad_shp$admin1_Oblast <- data.frame(x = 1:5)
  expect_error(pti_plot_boundaries(bad_shp))
})

test_that("pti_plot_boundaries: unknown highlight_level produces cli_abort", {
  data(ukr_shp, package = "devPTIpack")
  expect_error(pti_plot_boundaries(ukr_shp, highlight_level = "admin9_Fake"))
})

# ---------------------------------------------------------------------------
# pti_plot_histogram()
# ---------------------------------------------------------------------------

test_that("pti_plot_histogram: returns a ggplot object", {
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_plot_histogram(
    data = ukr_mtdt_full$admin1_Oblast,
    var  = "var_nval3_skewd_adm1"
  )
  expect_s3_class(result, "gg")
})

test_that("pti_plot_histogram: contains geom_vline layers for percentiles", {
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_plot_histogram(
    data        = ukr_mtdt_full$admin1_Oblast,
    var         = "var_nval3_skewd_adm1",
    percentiles = c(0.25, 0.5, 0.75)
  )
  layer_geoms <- vapply(result$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomVline" %in% layer_geoms)
  n_vlines <- sum(layer_geoms == "GeomVline")
  expect_equal(n_vlines, 3L)
})

test_that("pti_plot_histogram: works on an sf object (area column)", {
  data(ukr_shp, package = "devPTIpack")
  result <- pti_plot_histogram(ukr_shp$admin1_Oblast, var = "area")
  expect_s3_class(result, "gg")
})

test_that("pti_plot_histogram: var not in data produces an error", {
  data(ukr_mtdt_full, package = "devPTIpack")
  expect_error(
    pti_plot_histogram(ukr_mtdt_full$admin1_Oblast, "nonexistent_column")
  )
})

test_that("pti_plot_histogram: percentiles=NULL skips vlines", {
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_plot_histogram(
    data        = ukr_mtdt_full$admin1_Oblast,
    var         = "var_nval3_skewd_adm1",
    percentiles = NULL
  )
  expect_s3_class(result, "gg")
  layer_geoms <- vapply(result$layers, function(l) class(l$geom)[1], character(1))
  expect_false("GeomVline" %in% layer_geoms)
})

# ---------------------------------------------------------------------------
# pti_summary_table()
# ---------------------------------------------------------------------------

test_that("pti_summary_table type='overview': returns reactable htmlwidget", {
  skip_if_not_installed("reactable")
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_summary_table(ukr_mtdt_full, type = "overview")
  expect_s3_class(result, "reactable")
  expect_s3_class(result, "htmlwidget")
})

test_that("pti_summary_table type='overview': one row per metadata variable", {
  skip_if_not_installed("reactable")
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_summary_table(ukr_mtdt_full, type = "overview")
  widget_data <- jsonlite::fromJSON(result$x$tag$attribs$data)
  expect_equal(nrow(widget_data), nrow(ukr_mtdt_full$metadata))
})

test_that("pti_summary_table type='overview': contains required column names", {
  skip_if_not_installed("reactable")
  data(ukr_mtdt_full, package = "devPTIpack")
  result <- pti_summary_table(ukr_mtdt_full, type = "overview")
  widget_data <- jsonlite::fromJSON(result$x$tag$attribs$data)
  required_cols <- c("var_name", "pillar_name", "spatial_level",
                     "fltr_exclude_pti", "fltr_exclude_explorer",
                     "min", "mean", "max")
  expect_true(all(required_cols %in% names(widget_data)))
})

test_that("pti_summary_table type='hex': returns reactable htmlwidget", {
  skip_if_not_installed("reactable")
  mock_hex <- tibble::tibble(
    hex_id      = paste0("hex_", 1:10),
    nightlights = c(1.2, NA, 3.4, NA, 5.6, 7.8, NA, 9.0, 1.1, 2.2),
    poverty     = c(0.1, 0.2, NA, 0.4, 0.5, NA, 0.7, 0.8, 0.9, NA)
  )
  result <- pti_summary_table(mock_hex, type = "hex")
  expect_s3_class(result, "reactable")
  expect_s3_class(result, "htmlwidget")
})

test_that("pti_summary_table type='hex': one row per non-hex_id variable", {
  skip_if_not_installed("reactable")
  mock_hex <- tibble::tibble(
    hex_id  = paste0("hex_", 1:5),
    var_a   = c(1.0, NA, 3.0, 4.0, NA),
    var_b   = c(0.1, 0.2, NA, 0.4, 0.5)
  )
  result <- pti_summary_table(mock_hex, type = "hex")
  widget_data <- jsonlite::fromJSON(result$x$tag$attribs$data)
  expect_equal(nrow(widget_data), 2L)  # var_a, var_b (not hex_id)
})

test_that("pti_summary_table type='hex': coverage % is correct", {
  skip_if_not_installed("reactable")
  mock_hex <- tibble::tibble(
    hex_id = paste0("hex_", 1:4),
    my_var = c(1.0, NA, 3.0, NA)   # 2 non-missing out of 4 = 50%
  )
  result <- pti_summary_table(mock_hex, type = "hex")
  widget_data <- jsonlite::fromJSON(result$x$tag$attribs$data)
  expect_true("coverage_pct" %in% names(widget_data))
  expect_equal(widget_data$coverage_pct, 50)
})

test_that("pti_summary_table: invalid type is rejected", {
  data(ukr_mtdt_full, package = "devPTIpack")
  expect_error(pti_summary_table(ukr_mtdt_full, type = "invalid"))
})

# ---------------------------------------------------------------------------
# pti_plot_choropleth() — arch-13 §H / issue #157
#   Contract: pti_plot_choropleth(data, var) -> single ggplot choropleth.
#   `data` is one sf layer already carrying the numeric `var` column.

test_that("pti_plot_choropleth: returns a ggplot object", {
  result <- pti_plot_choropleth(ukr_shp$admin1_Oblast, "area")
  expect_s3_class(result, "gg")
})

test_that("pti_plot_choropleth: an all-NA variable column still returns a gg", {
  layer <- ukr_shp$admin1_Oblast
  layer$na_var <- NA_real_
  result <- pti_plot_choropleth(layer, "na_var")
  expect_s3_class(result, "gg")
})

test_that("pti_plot_choropleth: non-sf data produces an error", {
  expect_error(
    pti_plot_choropleth(ukr_mtdt_full$admin1_Oblast, "var_nval3_skewd_adm1"),
    regexp = "sf"
  )
})

test_that("pti_plot_choropleth: var not in data produces an error", {
  expect_error(
    pti_plot_choropleth(ukr_shp$admin1_Oblast, "no_such_column"),
    regexp = "column"
  )
})

test_that("pti_plot_choropleth: non-numeric var produces an error", {
  expect_error(
    pti_plot_choropleth(ukr_shp$admin1_Oblast, "admin1Name"),
    regexp = "numeric"
  )
})

test_that("pti_plot_choropleth: zero-row data produces an error", {
  expect_error(
    pti_plot_choropleth(ukr_shp$admin1_Oblast[0, ], "area"),
    regexp = "row"
  )
})
