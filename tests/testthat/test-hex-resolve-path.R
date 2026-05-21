# Tier-1 tests for hex_resolve_path() (issue #185).
#
# Verifies the HTTP(S) → local tempfile shim that lets hex_fetch_source()
# open parquet URLs that arrow::FileSystem$from_uri() doesn't recognise.

test_that("hex_resolve_path passes non-HTTP paths through unchanged", {
  expect_identical(
    devPTIpack:::hex_resolve_path("s3://bucket/x.parquet"),
    "s3://bucket/x.parquet"
  )
  expect_identical(
    devPTIpack:::hex_resolve_path("/var/data/local.parquet"),
    "/var/data/local.parquet"
  )
  expect_identical(
    devPTIpack:::hex_resolve_path("fake://registry.parquet"),
    "fake://registry.parquet"
  )
  expect_identical(
    devPTIpack:::hex_resolve_path("file:///tmp/local.parquet"),
    "file:///tmp/local.parquet"
  )
})

test_that("hex_resolve_path downloads https URLs to a local tempfile", {
  captured <- list(url = NULL, dest = NULL, mode = NULL, quiet = NULL)
  fake_dl <- function(url, destfile, mode = "w", quiet = FALSE, ...) {
    captured$url   <<- url
    captured$dest  <<- destfile
    captured$mode  <<- mode
    captured$quiet <<- quiet
    file.create(destfile)
    invisible(0L)
  }

  result <- devPTIpack:::hex_resolve_path(
    "https://datacatalogfiles.worldbank.org/x.parquet",
    downloader = fake_dl
  )

  expect_false(startsWith(result, "https://"))
  expect_match(result, "\\.parquet$")
  expect_identical(captured$url, "https://datacatalogfiles.worldbank.org/x.parquet")
  expect_identical(captured$dest, result)
  expect_identical(captured$mode, "wb")
  expect_true(captured$quiet)
})

test_that("hex_resolve_path also handles http:// (not just https://)", {
  fake_dl <- function(url, destfile, ...) {
    file.create(destfile)
    invisible(0L)
  }
  result <- devPTIpack:::hex_resolve_path(
    "http://example.com/x.parquet",
    downloader = fake_dl
  )
  expect_false(startsWith(result, "http://"))
  expect_match(result, "\\.parquet$")
})

test_that("hex_fetch_source resolves https path before calling dataset_loader", {
  # End-to-end: an HTTPS URL in vars$path should reach dataset_loader as
  # the downloaded tempfile, not the original URL.
  captured_loader_path <- NULL
  spy_loader <- function(path) {
    captured_loader_path <<- path
    tibble::tibble(
      hex_id    = "866ad8d47ffffff",
      pop       = 100,
      pop_flood = 10
    )
  }
  fake_dl <- function(url, destfile, ...) {
    file.create(destfile)
    invisible(0L)
  }

  pop_v <- devPTIpack:::pti_hex_var(
    source_col     = "pop",
    canonical_name = "population",
    var_name       = "Population",
    time_col       = NA_character_,
    weight         = "none",
    fun            = "sum",
    internal       = TRUE,
    path           = "https://datacatalogfiles.worldbank.org/x.parquet",
    hex_col        = "hex_id"
  )
  flood_v <- devPTIpack:::pti_hex_var(
    source_col     = "pop_flood",
    canonical_name = "flood_exposure_15cm_1in100",
    var_name       = "Flood Exposure",
    time_col       = NA_character_,
    weight         = "none",
    fun            = "sum",
    internal       = FALSE,
    path           = "https://datacatalogfiles.worldbank.org/x.parquet",
    hex_col        = "hex_id"
  )
  vars <- list(flood_exposure_15cm_1in100 = flood_v, population = pop_v)

  # Stub the download.file inside hex_resolve_path's downloader default.
  testthat::local_mocked_bindings(
    download.file = fake_dl,
    .package = "utils"
  )

  result <- fetch_hex_data(
    hex_ids        = "866ad8d47ffffff",
    vars           = vars,
    dataset_loader = spy_loader
  )

  expect_s3_class(result, "tbl_df")
  expect_false(is.null(captured_loader_path))
  expect_false(startsWith(captured_loader_path, "https://"))
  expect_match(captured_loader_path, "\\.parquet$")
})

# ---------------------------------------------------------------------------
# hex_curl_download() — retry + resume downloader (issue #190)

test_that("hex_resolve_path defaults to the retry+resume curl downloader", {
  expect_identical(
    formals(devPTIpack:::hex_resolve_path)$downloader,
    quote(hex_curl_download)
  )
})

test_that("hex_curl_download calls download.file with curl + retry/resume flags", {
  captured <- list()
  testthat::local_mocked_bindings(
    download.file = function(url, destfile, method, extra, ...) {
      captured$url    <<- url
      captured$method <<- method
      captured$extra  <<- extra
      invisible(0L)
    },
    .package = "utils"
  )

  devPTIpack:::hex_curl_download(
    "https://datacatalogfiles.worldbank.org/x.parquet",
    tempfile(fileext = ".parquet")
  )

  expect_identical(captured$method, "curl")
  # `-C -` resume, retry on dropped streams, and a non-curl user-agent.
  expect_true(all(c("-C", "-") %in% captured$extra))
  expect_true("--retry" %in% captured$extra)
  expect_true("--retry-all-errors" %in% captured$extra)
  expect_true("-A" %in% captured$extra)
  expect_false(any(grepl("^curl/", captured$extra)))
})
