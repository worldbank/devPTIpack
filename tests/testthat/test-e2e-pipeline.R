# End-to-end pipeline test (#163). Scaffolds a fresh PTI project with
# create_new_pti(), runs the full 00-master.R pipeline headlessly, and
# asserts every app-data/ + docs/ deployment artefact exists and is
# valid. This is the definitive quality gate for the arch-13 pipeline
# redesign (#149).
#
# GATED: the whole file is inert unless PTI_RUN_E2E=true. It is heavy --
# real Quarto renders plus a live World Bank hex-data fetch over the
# internet, ~5-10 min -- so it must never run inside the per-PR
# `tests.yaml` budget. The dedicated `.github/workflows/e2e-pipeline.yml`
# workflow sets PTI_RUN_E2E=true and runs it on a schedule / on `main`.
#
# Run locally with:
#   PTI_RUN_E2E=true Rscript -e 'devtools::test(filter = "e2e-pipeline")'
# devPTIpack must be *installed* (not just load_all'd): the Quarto step
# renders spawn fresh R processes that `library(devPTIpack)`, which a
# load_all() session does not reach.
#
# Ethiopia scenario: #163 also specifies an Ethiopia run, but that needs
# `get_country_shapes("ETH")` to fetch boundaries -- blocked on Inf-4
# (#148), which is unbuilt, and no Ethiopia data is bundled. The
# Ethiopia test below skip()s until #148 lands.

suppressPackageStartupMessages(library(shiny))

.e2e_enabled <- identical(Sys.getenv("PTI_RUN_E2E"), "true")

# ---------------------------------------------------------------------------
# Rwanda -- scaffold + full 00-master.R run, once, at file scope.
#
# `.rwa` is "ok" on success, or the error message string on failure, so
# the first test below can fail loudly with an actionable message.

.rwa_proj    <- NULL
.rwa         <- NULL
.rwa_elapsed <- NA_real_

if (.e2e_enabled) {
  .rwa_proj <- tempfile("e2e-rwa-")
  withr::defer(unlink(.rwa_proj, recursive = TRUE), envir = teardown_env())

  .rwa <- tryCatch(
    {
      create_new_pti(.rwa_proj, app_name = "Rwanda PTI", open = FALSE)
      .t <- system.time(
        # The real master script -- every quarto_render() call, the
        # data-quality report, and the docs/ website build.
        withr::with_dir(.rwa_proj, source("00-master.R", local = new.env()))
      )
      .rwa_elapsed <- unname(.t[["elapsed"]])
      "ok"
    },
    error = function(e) conditionMessage(e)
  )

  if (identical(.rwa, "ok")) {
    message(sprintf("E2E Rwanda pipeline finished in %.0f s.", .rwa_elapsed))
  }
}

# Path inside the scaffolded project (absolute -- safe regardless of wd).
.rwa_path <- function(...) file.path(.rwa_proj, ...)

# Guard for the per-artefact tests: skip unless the pipeline completed,
# so a Step-N failure surfaces once (in the test below) rather than as a
# cascade of confusing downstream failures.
.skip_unless_pipeline_ok <- function() {
  skip_if_not(.e2e_enabled,
              "Set PTI_RUN_E2E=true to run the E2E pipeline test.")
  skip_if_not(identical(.rwa, "ok"),
              "Pipeline did not complete -- see the run-without-error test.")
}

# ---------------------------------------------------------------------------

test_that("Rwanda E2E: 00-master.R runs the whole pipeline without error", {
  skip_if_not(.e2e_enabled,
              "Set PTI_RUN_E2E=true to run the E2E pipeline test.")
  expect_identical(
    .rwa, "ok",
    info = paste0(
      "source(\"00-master.R\") aborted in the scaffolded Rwanda project.\n",
      "Error: ", .rwa
    )
  )
})

test_that("Rwanda E2E: create_new_pti() replaced every {{APP_NAME}} token", {
  .skip_unless_pipeline_ok()

  txt <- list.files(
    .rwa_proj, recursive = TRUE, full.names = TRUE,
    pattern = "\\.(qmd|R|md|yml|yaml)$"
  )
  offenders <- Filter(
    function(f) any(grepl("{{APP_NAME}}", readLines(f, warn = FALSE),
                          fixed = TRUE)),
    txt
  )
  expect_equal(
    offenders, character(0),
    info = paste("Unreplaced {{APP_NAME}} token in:",
                 paste(basename(offenders), collapse = ", "))
  )
})

test_that("Rwanda E2E: app-data/shapes.rds is valid", {
  .skip_unless_pipeline_ok()

  p <- .rwa_path("app-data", "shapes.rds")
  expect_true(file.exists(p), info = "Step 1 did not write app-data/shapes.rds")

  shp  <- readRDS(p)
  diag <- validate_geometries(shp, error_on_fail = FALSE)
  expect_equal(diag$status, "pass",
               info = "validate_geometries() failed on the compiled shapes")
})

test_that("Rwanda E2E: app-data/metadata.xlsx is readable and has variables", {
  .skip_unless_pipeline_ok()

  p <- .rwa_path("app-data", "metadata.xlsx")
  expect_true(file.exists(p), info = "Step 5 did not write app-data/metadata.xlsx")

  compiled <- fct_template_reader(p)
  expect_true("metadata" %in% names(compiled))
  expect_gt(nrow(compiled$metadata), 0L)
})

test_that("Rwanda E2E: Step 4 wrote app-data/metadata-hex.xlsx", {
  .skip_unless_pipeline_ok()

  expect_true(
    file.exists(.rwa_path("app-data", "metadata-hex.xlsx")),
    info = "Step 4 (HEX data) runs by default but produced no metadata-hex.xlsx"
  )
})

test_that("Rwanda E2E: the data-quality report rendered (pti-metadata.html)", {
  .skip_unless_pipeline_ok()

  p <- .rwa_path("app-data", "pti-metadata.html")
  expect_true(file.exists(p), info = "05-compile-report.qmd produced no HTML")
  expect_gt(file.size(p), 0L)
})

test_that("Rwanda E2E: the data-quality website rendered (docs/index.html)", {
  .skip_unless_pipeline_ok()

  p <- .rwa_path("docs", "index.html")
  expect_true(file.exists(p),
              info = "quarto_render() produced no docs/index.html")
  expect_gt(file.size(p), 0L)
})

test_that("Rwanda E2E: launch_pti() accepts the compiled outputs", {
  .skip_unless_pipeline_ok()

  shp  <- readRDS(.rwa_path("app-data", "shapes.rds"))
  mtdt <- fct_template_reader(.rwa_path("app-data", "metadata.xlsx"))

  app <- launch_pti(
    shp_dta  = shp,
    inp_dta  = mtdt,
    app_name = "Rwanda PTI E2E"
  )
  expect_s3_class(app, "shiny.appobj")
})

# ---------------------------------------------------------------------------
# Ethiopia -- blocked on Inf-4.

test_that("Ethiopia E2E: blocked on get_country_shapes() (#148)", {
  skip(paste(
    "Ethiopia scenario blocked on Inf-4 (#148): get_country_shapes() is",
    "not implemented and no Ethiopia data is bundled. Enable this test",
    "once #148 lands."
  ))
})
