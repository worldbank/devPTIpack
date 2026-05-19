# Tier-1 tests for pti_patch_admin_sheet() — arch-13 §E (#153)
#
# Contract (from tdd-new-fn session 2026-05-18):
#   - Returns invisible(output_path)
#   - Explicit pcod_col argument identifies the join key column in values
#   - cli_abort() when non-Pcod columns in values are NOT in var_code
#   - Partial patch allowed: var_codes with no matching column get NA

# ---------------------------------------------------------------------------
# Helpers — build minimal test fixtures
# ---------------------------------------------------------------------------

make_skeleton <- function(path, var_codes, admin_level = "admin2_District",
                          pcod_values = c("RWA002001", "RWA002002")) {
  metadata_sheet <- tibble::tibble(
    var_code    = var_codes,
    admin_level = admin_level,
    var_name    = var_codes
  )
  admin_sheet <- tibble::tibble(
    admin2Pcod = pcod_values
  )
  sheets <- stats::setNames(
    list(metadata_sheet, admin_sheet),
    c("metadata", admin_level)
  )
  writexl::write_xlsx(sheets, path)
  invisible(path)
}

# ---------------------------------------------------------------------------
# Happy path — complete patch (all var_codes supplied)
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: complete patch writes correct values", {
  tmp     <- withr::local_tempdir()
  src     <- file.path(tmp, "skeleton.xlsx")
  out     <- file.path(tmp, "result.xlsx")
  var_codes <- c("poverty_rate", "literacy_rate")
  make_skeleton(src, var_codes)

  values <- tibble::tibble(
    admin2Pcod   = c("RWA002001", "RWA002002"),
    poverty_rate  = c(0.4, 0.2),
    literacy_rate = c(0.7, 0.9)
  )

  result <- pti_patch_admin_sheet(
    mtdt_path   = src,
    admin_level = "admin2_District",
    values      = values,
    pcod_col    = "admin2Pcod",
    output_path = out
  )

  expect_true(file.exists(out))
  patched <- readxl::read_xlsx(out, sheet = "admin2_District")
  expect_equal(patched$poverty_rate,  c(0.4, 0.2))
  expect_equal(patched$literacy_rate, c(0.7, 0.9))
})

# ---------------------------------------------------------------------------
# Happy path — partial patch (only some var_codes supplied → NA for rest)
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: partial patch fills missing var_codes with NA", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, c("poverty_rate", "literacy_rate", "road_density"))

  values <- tibble::tibble(
    admin2Pcod  = c("RWA002001", "RWA002002"),
    poverty_rate = c(0.4, 0.2)
  )

  pti_patch_admin_sheet(
    mtdt_path   = src,
    admin_level = "admin2_District",
    values      = values,
    pcod_col    = "admin2Pcod",
    output_path = out
  )

  patched <- readxl::read_xlsx(out, sheet = "admin2_District")
  expect_true("poverty_rate"  %in% names(patched))
  expect_true("road_density"  %in% names(patched))
  expect_equal(patched$poverty_rate, c(0.4, 0.2))
  expect_true(all(is.na(patched$road_density)))
})

# ---------------------------------------------------------------------------
# Return value is invisible(output_path)
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: returns output_path invisibly", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, "poverty_rate")

  values <- tibble::tibble(admin2Pcod = "RWA002001", poverty_rate = 0.4)
  ret <- withVisible(pti_patch_admin_sheet(
    mtdt_path   = src,
    admin_level = "admin2_District",
    values      = values,
    pcod_col    = "admin2Pcod",
    output_path = out
  ))

  expect_equal(ret$value, out)
  expect_false(ret$visible)
})

# ---------------------------------------------------------------------------
# Other sheets are preserved unchanged
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: sheets not targeted are preserved", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, "poverty_rate")

  # Add a second admin sheet to the skeleton
  all_sheets <- c(
    readxl::excel_sheets(src),
    "admin1_Province"
  )
  existing <- purrr::map(
    stats::setNames(all_sheets[all_sheets != "admin1_Province"], all_sheets[all_sheets != "admin1_Province"]),
    ~ readxl::read_xlsx(src, sheet = .x)
  )
  extra_sheet <- tibble::tibble(admin1Pcod = "RWA001", some_col = 99)
  all_data <- c(existing, list(admin1_Province = extra_sheet))
  writexl::write_xlsx(all_data, src)

  values <- tibble::tibble(admin2Pcod = "RWA002001", poverty_rate = 0.4)
  pti_patch_admin_sheet(
    mtdt_path   = src,
    admin_level = "admin2_District",
    values      = values,
    pcod_col    = "admin2Pcod",
    output_path = out
  )

  preserved <- readxl::read_xlsx(out, sheet = "admin1_Province")
  expect_equal(preserved$some_col, 99)
})

# ---------------------------------------------------------------------------
# Error — extra columns in values not in var_code
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: aborts when values has columns not in var_code", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, "poverty_rate")

  values <- tibble::tibble(
    admin2Pcod   = "RWA002001",
    poverty_rate = 0.4,
    unknown_col  = 99        # not in var_code
  )

  expect_error(
    pti_patch_admin_sheet(
      mtdt_path   = src,
      admin_level = "admin2_District",
      values      = values,
      pcod_col    = "admin2Pcod",
      output_path = out
    ),
    class = "rlang_error"
  )
})

# ---------------------------------------------------------------------------
# Error — mtdt_path does not exist
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: aborts when mtdt_path does not exist", {
  tmp <- withr::local_tempdir()
  expect_error(
    pti_patch_admin_sheet(
      mtdt_path   = file.path(tmp, "nonexistent.xlsx"),
      admin_level = "admin2_District",
      values      = tibble::tibble(admin2Pcod = "RWA002001", poverty_rate = 0.4),
      pcod_col    = "admin2Pcod",
      output_path = file.path(tmp, "result.xlsx")
    ),
    class = "rlang_error"
  )
})

# ---------------------------------------------------------------------------
# Error — admin_level sheet not in workbook
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: aborts when admin_level sheet is missing from workbook", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, "poverty_rate")

  expect_error(
    pti_patch_admin_sheet(
      mtdt_path   = src,
      admin_level = "admin3_Sector",   # not in workbook
      values      = tibble::tibble(admin2Pcod = "RWA002001", poverty_rate = 0.4),
      pcod_col    = "admin2Pcod",
      output_path = out
    ),
    class = "rlang_error"
  )
})

# ---------------------------------------------------------------------------
# Error — pcod_col not found in values
# ---------------------------------------------------------------------------

test_that("pti_patch_admin_sheet: aborts when pcod_col is missing from values", {
  tmp <- withr::local_tempdir()
  src <- file.path(tmp, "skeleton.xlsx")
  out <- file.path(tmp, "result.xlsx")
  make_skeleton(src, "poverty_rate")

  values <- tibble::tibble(wrongkey = "RWA002001", poverty_rate = 0.4)

  expect_error(
    pti_patch_admin_sheet(
      mtdt_path   = src,
      admin_level = "admin2_District",
      values      = values,
      pcod_col    = "admin2Pcod",      # not in values
      output_path = out
    ),
    class = "rlang_error"
  )
})
