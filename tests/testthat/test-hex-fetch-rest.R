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
    time_col            = "year",
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
