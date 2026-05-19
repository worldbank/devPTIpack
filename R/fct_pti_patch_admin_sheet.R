#' Patch an administrative metadata sheet with supplied indicator values
#'
#' Rewrites one administrative sheet in a metadata workbook by validating
#' supplied value columns against the workbook metadata and joining those
#' values to the existing administrative rows by P-code.
#'
#' @param mtdt_path Character. Path to the source metadata `.xlsx` workbook.
#' @param admin_level Character. Name of the administrative sheet to patch.
#' @param values A data frame or tibble containing the P-code column and one
#'   or more indicator columns whose names match `metadata$var_code`.
#' @param pcod_col Character. Name of the P-code join column in `values`.
#' @param output_path Character. Path where the patched metadata `.xlsx`
#'   workbook should be written.
#'
#' @return Invisibly returns `output_path`.
#'
#' @importFrom cli cli_abort
#' @importFrom dplyr left_join
#' @importFrom purrr map set_names
#' @importFrom readxl excel_sheets read_xlsx
#' @importFrom writexl write_xlsx
#' @family data-input
#' @export
#'
#' @examples
#' \dontrun{
#' pti_patch_admin_sheet(
#'   mtdt_path = "sample-data/metadata-skeleton.xlsx",
#'   admin_level = "admin2_District",
#'   values = adm2_values,
#'   pcod_col = "admin2Pcod",
#'   output_path = "app-data/metadata-user.xlsx"
#' )
#' }
pti_patch_admin_sheet <- function(mtdt_path = "sample-data/metadata-skeleton.xlsx",
                                  admin_level = "admin2_District",
                                  values,
                                  pcod_col,
                                  output_path = "app-data/metadata-user.xlsx") {
  if (!file.exists(mtdt_path)) {
    cli::cli_abort("Metadata workbook does not exist: {.path {mtdt_path}}.")
  }

  sheet_names <- readxl::excel_sheets(mtdt_path)

  if (!admin_level %in% sheet_names) {
    cli::cli_abort(
      "Administrative sheet {.val {admin_level}} was not found in {.path {mtdt_path}}."
    )
  }

  if (!pcod_col %in% names(values)) {
    cli::cli_abort("P-code column {.val {pcod_col}} was not found in `values`.")
  }

  metadata <- readxl::read_xlsx(mtdt_path, sheet = "metadata")
  allowed_var_codes <-
    metadata[metadata$admin_level == admin_level, "var_code", drop = TRUE]

  value_columns <- setdiff(names(values), pcod_col)
  extra_columns <- setdiff(value_columns, allowed_var_codes)

  if (length(extra_columns) > 0) {
    cli::cli_abort(c(
      "All non-P-code columns in `values` must appear in `metadata$var_code`.",
      x = "Unknown column{?s}: {.val {extra_columns}}."
    ))
  }

  existing_admin <- readxl::read_xlsx(mtdt_path, sheet = admin_level)
  join_key <- find_admin_join_key(existing_admin, values, pcod_col, admin_level)
  join_by <- stats::setNames(pcod_col, join_key)

  base_admin <- existing_admin[, setdiff(names(existing_admin), allowed_var_codes), drop = FALSE]
  supplied_values <- values[, c(pcod_col, value_columns), drop = FALSE]

  patched_admin <- dplyr::left_join(base_admin, supplied_values, by = join_by)
  missing_var_codes <- setdiff(allowed_var_codes, names(patched_admin))

  for (var_code in missing_var_codes) {
    patched_admin[[var_code]] <- NA
  }

  workbook_sheets <-
    sheet_names |>
    purrr::set_names() |>
    purrr::map(function(sheet) {
      if (identical(sheet, admin_level)) {
        patched_admin
      } else {
        readxl::read_xlsx(mtdt_path, sheet = sheet)
      }
    })

  writexl::write_xlsx(workbook_sheets, output_path)

  invisible(output_path)
}

find_admin_join_key <- function(existing_admin, values, pcod_col, admin_level) {
  if (pcod_col %in% names(existing_admin)) {
    return(pcod_col)
  }

  common_columns <- intersect(names(existing_admin), names(values))

  if (length(common_columns) > 0) {
    return(common_columns[[1]])
  }

  pcod_columns <- grep("Pcod$", names(existing_admin), value = TRUE)

  if (length(pcod_columns) > 0) {
    return(pcod_columns[[1]])
  }

  admin_prefix <- sub("_.*$", "", admin_level)
  admin_columns <- grep(paste0("^", admin_prefix), names(existing_admin), value = TRUE)

  if (length(admin_columns) > 0) {
    return(admin_columns[[1]])
  }

  cli::cli_abort(
    "Could not identify a P-code join column in the {.val {admin_level}} sheet."
  )
}
