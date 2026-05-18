#' Scaffold a new PTI app project
#'
#' Copies the bundled `template_pti` skeleton (located inside the
#' installed package via [app_sys()]) into a new project directory,
#' creating an `app.R` and an RStudio project file. When called from
#' an RStudio session, the project is opened automatically. Use this
#' to bootstrap a fresh PTI deployment that you then point at your
#' own shapes and metadata.
#'
#' @param path Character. Full path to the new project directory.
#'   The directory is created automatically; if it already exists the
#'   user is prompted (via [yesno::yesno()]) before any files are
#'   overwritten. `path = "."` writes into the current working
#'   directory.
#' @param open Logical. If `TRUE` (default) and RStudio is active,
#'   the user is prompted before the project is opened in a new
#'   RStudio window. In other environments (Positron, VSCode,
#'   headless R) the project path is printed and no auto-open is
#'   attempted.
#' @param app_name Character. Display name for the project; replaces
#'   `{{COUNTRY NAME}}` and `{{APP_NAME}}` tokens in scaffolded files.
#'   Defaults to the basename of `path`.
#'
#' @return Invisibly, the absolute path to the scaffolded project
#'   (as returned by [fs::path_abs()]). Returns `invisible(NULL)` if
#'   the user declines the overwrite prompt.
#'
#' @importFrom fs path_file dir_copy path_expand dir_create path_abs dir_exists
#' @importFrom cli cli_inform
#' @importFrom yesno yesno
#' @importFrom rstudioapi hasFun initializeProject openProject
#' @family pti-launch
#' @export
#'
#' @examples
#' # Scaffold into a temporary directory; works headlessly because
#' # rstudioapi::hasFun("initializeProject") is FALSE outside RStudio.
#' new_app <- file.path(tempdir(), "demo_pti")
#' create_new_pti(new_app, open = FALSE)
#' list.files(new_app)
#' unlink(new_app, recursive = TRUE)
create_new_pti <- function(path, open = TRUE, app_name = basename(path)) {

  path <- fs::path_expand(path)

  if (path == "." & app_name == fs::path_file(path)) {
    app_name <- fs::path_file(getwd())
  }

  if (fs::dir_exists(path)) {
    res <- yesno::yesno(paste("The path", path, "already exists, override?"))
    if (!res) {
      return(invisible(NULL))
    }
  }

  fs::dir_create(path, recurse = TRUE)

  if (rstudioapi::hasFun("initializeProject")) {
    rstudioapi::initializeProject(path = path)
  } else {
    cli::cli_inform(c(
      "v" = "Project scaffolded at {.path {path}}",
      "i" = "Open this folder as a new project in your IDE to get started."
    ))
  }

  from <- system.file("template_pti", package = "devPTIpack")
  fs::dir_copy(path = from, new_path = path, overwrite = TRUE)

  # Replace template tokens in all text files
  text_exts <- c("\\.R$", "\\.md$", "\\.qmd$", "\\.yml$", "\\.yaml$", "\\.txt$")
  all_files <- list.files(path, recursive = TRUE, all.files = TRUE, full.names = TRUE)
  text_files <- all_files[grepl(paste(text_exts, collapse = "|"), all_files)]

  for (f in text_files) {
    lines <- readLines(f, warn = FALSE)
    if (any(grepl("{{COUNTRY NAME}}", lines, fixed = TRUE)) ||
        any(grepl("{{APP_NAME}}", lines, fixed = TRUE))) {
      lines <- gsub("{{COUNTRY NAME}}", app_name, lines, fixed = TRUE)
      lines <- gsub("{{APP_NAME}}", app_name, lines, fixed = TRUE)
      writeLines(lines, f)
    }
  }

  cli::cli_inform(c(
    "v" = "Project directory created",
    "v" = "Skeleton files copied",
    "v" = "Template tokens replaced (app_name = \"{app_name}\")",
    "i" = "Open app.R and set your data paths",
    "i" = "Run source('00-master.R') to build the app data"
  ))

  if (open && rstudioapi::hasFun("openProject")) {
    do_open <- tryCatch(
      yesno::yesno("Open the project in RStudio now?"),
      error = function(e) TRUE
    )
    if (do_open) rstudioapi::openProject(path = path)
  } else if (open) {
    cli::cli_inform(c("i" = "Project path: {.path {path}}"))
  }

  return(invisible(fs::path_abs(path)))

}
