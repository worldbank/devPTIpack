make_rest_static_var <- function(src_col = "fires_density_mean",
                                 canonical = "fires_density") {
  v <- devPTIpack:::pti_hex_var(
    source_col     = src_col,
    canonical_name = canonical,
    var_name       = canonical,
    time_col       = NA_character_,
    weight         = "area",
    fun            = "mean"
  )
  v$backend <- "rest"
  v$api_root <- "https://space2stats.ds.io"
  v$hex_col <- "hex_id"
  v
}

make_rest_template_var <- function() {
  v <- devPTIpack:::pti_hex_var(
    source_col_template = "ntl_{year}",
    canonical_name      = "nightlights",
    var_name            = "Night Lights ({year})",
    time_col            = NA_character_,
    years               = c(2020L, 2022L),
    weight              = "none",
    fun                 = "mean",
    resolved_cols       = c("ntl_2020", "ntl_2022")
  )
  v$backend <- "rest"
  v$api_root <- "https://space2stats.ds.io"
  v$hex_col <- "hex_id"
  v
}

make_rest_group <- function(vars, hex_col = "hex_id") {
  list(
    backend  = "rest",
    path     = NA_character_,
    api_root = "https://space2stats.ds.io",
    hex_col  = hex_col,
    vars     = vars
  )
}

test_that("hex_fetch_source_rest: static variable renamed to canonical name", {
  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  mockery::stub(fetch_rest, "httr2::req_perform", function(req) req)
  mockery::stub(fetch_rest, "httr2::resp_body_json", function(resp, ...) {
    data.frame(
      hex_id = c("86283082fffffff", "862830827ffffff"),
      fires_density_mean = c(1.5, 2.5),
      check.names = FALSE
    )
  })

  result <- fetch_rest(
    make_rest_group(list(fires_density = make_rest_static_var())),
    c("86283082fffffff", "862830827ffffff")
  )

  expect_true("fires_density" %in% names(result))
  expect_false("fires_density_mean" %in% names(result))
  expect_equal(result$fires_density, c(1.5, 2.5))
})

test_that("hex_fetch_source_rest: template variable produces canonical_year columns", {
  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  mockery::stub(fetch_rest, "httr2::req_perform", function(req) req)
  mockery::stub(fetch_rest, "httr2::resp_body_json", function(resp, ...) {
    data.frame(
      hex_id = "86283082fffffff",
      ntl_2020 = 10,
      ntl_2022 = 12,
      check.names = FALSE
    )
  })

  result <- fetch_rest(
    make_rest_group(list(nightlights = make_rest_template_var())),
    "86283082fffffff"
  )

  expect_true("nightlights_2020" %in% names(result))
  expect_true("nightlights_2022" %in% names(result))
  expect_false("ntl_2020" %in% names(result))
  expect_false("ntl_2022" %in% names(result))
})

test_that("hex_fetch_source_rest: >5000 hex IDs split into multiple POST requests", {
  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  call_count <- 0L
  mockery::stub(fetch_rest, "httr2::req_perform", function(req) {
    call_count <<- call_count + 1L
    req
  })
  mockery::stub(fetch_rest, "httr2::resp_body_json", function(resp, ...) {
    data.frame(
      hex_id = character(0),
      fires_density_mean = numeric(0),
      check.names = FALSE
    )
  })

  fetch_rest(
    make_rest_group(list(fires_density = make_rest_static_var())),
    sprintf("hex_%04d", seq_len(5001L))
  )

  expect_equal(call_count, 2L)
})

test_that("hex_fetch_source_rest: multi-chunk responses are row-bound correctly", {
  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  mockery::stub(fetch_rest, "httr2::req_perform", function(req) req)
  response_count <- 0L
  mockery::stub(fetch_rest, "httr2::resp_body_json", function(resp, ...) {
    response_count <<- response_count + 1L
    if (response_count == 1L) {
      data.frame(
        hex_id = sprintf("hex_%04d", seq_len(5000L)),
        fires_density_mean = seq_len(5000L),
        check.names = FALSE
      )
    } else {
      data.frame(
        hex_id = sprintf("hex_%04d", 5001:5002),
        fires_density_mean = 5001:5002,
        check.names = FALSE
      )
    }
  })

  result <- fetch_rest(
    make_rest_group(list(fires_density = make_rest_static_var())),
    sprintf("hex_%04d", seq_len(5002L))
  )

  expect_equal(nrow(result), 5002L)
})

# ---------------------------------------------------------------------------
# httptest2 contracts for Space2Stats API fixtures
# ---------------------------------------------------------------------------

test_that("hex_fetch_source_rest: Space2Stats static climate fields contract", {
  testthat::skip_if_not_installed("httptest2")

  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  hex_ids <- c("866ad8d47ffffff", "866ad8d4fffffff")
  vars <- list(
    fires_density = make_rest_static_var(
      "fires_density_mean",
      "fires_density"
    ),
    cyclone_frequency = make_rest_static_var(
      "cy_frequency_mean",
      "cyclone_frequency"
    ),
    landslide_susceptibility_2023 = make_rest_static_var(
      "landslide_susceptibility_mean_2023",
      "landslide_susceptibility_2023"
    ),
    drought_spei_1_5_rp100 = make_rest_static_var(
      "drought_spei_1_5_rp100_mean",
      "drought_spei_1_5_rp100"
    )
  )

  result <- httptest2::with_mock_api(
    fetch_rest(make_rest_group(vars), hex_ids)
  )

  expected <- names(vars)
  raw <- vapply(vars, `[[`, character(1), "source_col")
  expect_equal(nrow(result), 2L)
  expect_true(all(c("hex_id", expected) %in% names(result)))
  expect_false(any(raw %in% names(result)))
})

test_that("hex_fetch_source_rest: Space2Stats NTL template fields contract", {
  testthat::skip_if_not_installed("httptest2")

  fetch_rest <- devPTIpack:::hex_fetch_source_rest
  hex_ids <- c("866ad8d47ffffff", "866ad8d4fffffff")
  ntl <- devPTIpack:::pti_hex_var(
    source_col_template = "sum_viirs_ntl_{year}",
    canonical_name      = "nightlights",
    var_name            = "Night Lights ({year})",
    time_col            = NA_character_,
    years               = c(2020L, 2022L),
    weight              = "none",
    fun                 = "mean",
    resolved_cols       = c("sum_viirs_ntl_2020", "sum_viirs_ntl_2022")
  )

  result <- httptest2::with_mock_api(
    fetch_rest(make_rest_group(list(nightlights = ntl)), hex_ids)
  )

  expect_true(all(c("nightlights_2020", "nightlights_2022") %in% names(result)))
  raw <- c("sum_viirs_ntl_2020", "sum_viirs_ntl_2022")
  expect_false(any(raw %in% names(result)))
  expect_true(is.numeric(result$nightlights_2020))
  expect_true(is.numeric(result$nightlights_2022))
})

test_that("get_available_years: Space2Stats REST fields contract", {
  testthat::skip_if_not_installed("httptest2")

  subject <- devPTIpack::get_available_years
  ntl <- devPTIpack:::pti_hex_var(
    source_col_template = "sum_viirs_ntl_{year}",
    canonical_name      = "nightlights",
    var_name            = "Night Lights ({year})",
    time_col            = NA_character_,
    weight              = "none",
    fun                 = "mean"
  )
  registry <- list(space2stats = make_rest_group(list(nightlights = ntl)))
  mockery::stub(subject, "read_hex_registry", function() registry)

  result <- httptest2::with_mock_api(subject("nightlights"))

  expect_type(result, "integer")
  expect_gt(length(result), 0L)
  expect_true(2020L %in% result)
  expect_true(2022L %in% result)
  expect_identical(result, sort(result))
})

test_that("fetch_hex_data: end-to-end REST fetch with real registry names", {
  testthat::skip_if_not_installed("httptest2")

  hex_ids <- c("866ad8d47ffffff", "866ad8d4fffffff")

  # use_hex_vars() with real YAML canonical names; auto-injects
  # population. Since #196 population is also a Space2Stats REST
  # variable, so the whole fetch is a single REST request — no
  # parquet loader needed.
  vars <- devPTIpack::use_hex_vars(
    "fires_density", "cyclone_frequency", "landslide_susceptibility", "drought_spei"
  )

  result <- httptest2::with_mock_api(
    devPTIpack::fetch_hex_data(
      hex_ids, vars,
      available_years_lookup = list()
    )
  )

  expect_equal(nrow(result), 2L)
  expect_true("fires_density"            %in% names(result))
  expect_true("cyclone_frequency"        %in% names(result))
  expect_true("landslide_susceptibility" %in% names(result))
  expect_true("drought_spei"            %in% names(result))
  expect_true("population"              %in% names(result))
  expect_true(is.numeric(result$fires_density))
  expect_identical(names(result)[2L], "population")
})
