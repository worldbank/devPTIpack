testthat::test_that("create_new_pti scaffolds files headlessly", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  out <- subject(path, open = FALSE)

  testthat::expect_equal(out, fs::path_abs(path))
  testthat::expect_true(file.exists(file.path(path, "app.R")))
  testthat::expect_true(file.exists(file.path(path, "README.md")))
})

testthat::test_that("create_new_pti does not create .Rproj outside RStudio", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  subject(path, open = FALSE)

  rproj_files <- list.files(path, pattern = "[.]Rproj$", all.files = TRUE)
  testthat::expect_length(rproj_files, 0L)
})

testthat::test_that("create_new_pti emits cli message instead of erroring", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  testthat::expect_message(
    subject(path, open = FALSE),
    "Project scaffolded"
  )
})

testthat::test_that("create_new_pti calls rstudioapi in RStudio", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  calls <- new.env(parent = emptyenv())
  calls$initialize <- 0L
  calls$open <- 0L
  calls$initialize_path <- NULL
  calls$open_path <- NULL

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) TRUE)
  mockery::stub(subject, "rstudioapi::initializeProject", function(path) {
    calls$initialize <- calls$initialize + 1L
    calls$initialize_path <- path
    invisible(file.path(path, paste0(basename(path), ".Rproj")))
  })
  mockery::stub(subject, "rstudioapi::openProject", function(path) {
    calls$open <- calls$open + 1L
    calls$open_path <- path
    invisible(TRUE)
  })

  subject(path, open = TRUE)

  testthat::expect_equal(calls$initialize, 1L)
  testthat::expect_equal(calls$open, 1L)
  testthat::expect_equal(as.character(calls$initialize_path), path)
  testthat::expect_equal(as.character(calls$open_path), path)
})

testthat::test_that("create_new_pti does not open when open is FALSE", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  calls <- new.env(parent = emptyenv())
  calls$open <- 0L

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) TRUE)
  mockery::stub(subject, "rstudioapi::initializeProject", function(path) {
    invisible(TRUE)
  })
  mockery::stub(subject, "rstudioapi::openProject", function(path) {
    calls$open <- calls$open + 1L
    invisible(TRUE)
  })

  subject(path, open = FALSE)

  testthat::expect_equal(calls$open, 0L)
})

testthat::test_that("create_new_pti returns NULL when user declines overwrite", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  dir.create(path, recursive = TRUE)

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "yesno::yesno", function(...) FALSE)

  testthat::expect_null(subject(path, open = FALSE))
})

testthat::test_that("create_new_pti copies all skeleton files", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  subject(path, open = FALSE)

  from <- system.file("template_pti", package = "devPTIpack")
  expected <- list.files(from, all.files = TRUE, recursive = TRUE)
  actual <- list.files(path, all.files = TRUE, recursive = TRUE)

  testthat::expect_setequal(actual, expected)
})

# --- arch-13 §A contracts ------------------------------------------------

testthat::test_that("create_new_pti replaces {{COUNTRY NAME}} in app.R with app_name", {
  path <- file.path(withr::local_tempdir(), "my-pti")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  subject(path, open = FALSE, app_name = "Rwanda PTI")

  lines <- readLines(file.path(path, "app.R"))
  testthat::expect_false(
    any(grepl("{{COUNTRY NAME}}", lines, fixed = TRUE)),
    label = "{{COUNTRY NAME}} token must be replaced after scaffold"
  )
  testthat::expect_true(
    any(grepl("Rwanda PTI", lines, fixed = TRUE)),
    label = "app_name value must appear in scaffolded app.R"
  )
})

testthat::test_that("create_new_pti token replacement uses app_name default (basename of path)", {
  path <- file.path(withr::local_tempdir(), "angola-pti")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  subject(path, open = FALSE)

  lines <- readLines(file.path(path, "app.R"))
  testthat::expect_false(
    any(grepl("{{COUNTRY NAME}}", lines, fixed = TRUE)),
    label = "{{COUNTRY NAME}} must be gone even when app_name uses default"
  )
  testthat::expect_true(
    any(grepl("angola-pti", lines, fixed = TRUE)),
    label = "basename of path used as default app_name in scaffolded app.R"
  )
})

testthat::test_that("create_new_pti replaces {{APP_NAME}} tokens wherever they appear in scaffolded files", {
  path <- file.path(withr::local_tempdir(), "my-pti")
  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)

  subject(path, open = FALSE, app_name = "My PTI App")

  text_exts <- c("\\.R$", "\\.md$", "\\.qmd$", "\\.yml$", "\\.yaml$", "\\.txt$")
  all_files <- list.files(path, recursive = TRUE, all.files = TRUE, full.names = TRUE)
  text_files <- all_files[grepl(paste(text_exts, collapse = "|"), all_files)]

  has_token <- vapply(text_files, function(f) {
    any(grepl("{{APP_NAME}}", readLines(f, warn = FALSE), fixed = TRUE))
  }, logical(1L))

  testthat::expect_false(
    any(has_token),
    label = "No scaffolded text file should contain unreplaced {{APP_NAME}} after scaffold"
  )
})

testthat::test_that("create_new_pti prompts yesno before opening in RStudio (open = TRUE)", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  yesno_calls <- 0L

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) TRUE)
  mockery::stub(subject, "rstudioapi::initializeProject", function(path) invisible(TRUE))
  mockery::stub(subject, "yesno::yesno", function(...) {
    yesno_calls <<- yesno_calls + 1L
    TRUE
  })
  mockery::stub(subject, "rstudioapi::openProject", function(path) invisible(TRUE))

  subject(path, open = TRUE)

  testthat::expect_equal(yesno_calls, 1L)
})

testthat::test_that("create_new_pti skips openProject when yesno returns FALSE (open = TRUE)", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  open_calls <- 0L

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) TRUE)
  mockery::stub(subject, "rstudioapi::initializeProject", function(path) invisible(TRUE))
  mockery::stub(subject, "yesno::yesno", function(...) FALSE)
  mockery::stub(subject, "rstudioapi::openProject", function(path) {
    open_calls <<- open_calls + 1L
    invisible(TRUE)
  })

  subject(path, open = TRUE)

  testthat::expect_equal(open_calls, 0L)
})

testthat::test_that("create_new_pti does not prompt yesno for open when open = FALSE (RStudio)", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  yesno_calls <- 0L

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) TRUE)
  mockery::stub(subject, "rstudioapi::initializeProject", function(path) invisible(TRUE))
  mockery::stub(subject, "yesno::yesno", function(...) {
    yesno_calls <<- yesno_calls + 1L
    TRUE
  })
  mockery::stub(subject, "rstudioapi::openProject", function(path) invisible(TRUE))

  subject(path, open = FALSE)

  testthat::expect_equal(yesno_calls, 0L)
})

testthat::test_that("create_new_pti does not prompt yesno for open when headless (open = TRUE)", {
  path <- file.path(withr::local_tempdir(), "pti-app")
  yesno_calls <- 0L

  subject <- devPTIpack::create_new_pti
  mockery::stub(subject, "rstudioapi::hasFun", function(name) FALSE)
  mockery::stub(subject, "yesno::yesno", function(...) {
    yesno_calls <<- yesno_calls + 1L
    TRUE
  })

  subject(path, open = TRUE)

  testthat::expect_equal(yesno_calls, 0L)
})
