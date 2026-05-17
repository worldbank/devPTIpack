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
