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
#'   opens the new project in a new RStudio window after scaffolding.
#'   In other environments (Positron, VSCode, headless R) the project
#'   path is printed and no auto-open is attempted.
#' @param app_name Character. Display name for the project, used for
#'   the RStudio project file. Defaults to the basename of `path`.
#'
#' @return Invisibly, the absolute path to the scaffolded project
#'   (as returned by [fs::path_abs()]). Returns `invisible(NULL)` if
#'   the user declines the overwrite prompt.
#'
#' @importFrom fs path_file dir_copy path_expand dir_create path_abs dir_exists
#' @importFrom cli cat_rule cat_bullet cli_inform
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

  cli::cat_rule("Creating dir")
  fs::dir_create(path, recurse = TRUE)
  cli::cat_bullet("Created package directory")

  if (rstudioapi::hasFun("initializeProject")) {
    cli::cat_rule("RStudio project initialisation")
    rstudioapi::initializeProject(path = path)
  } else {
    cli::cli_inform(c(
      "v" = "Project scaffolded at {.path {path}}",
      "i" = "Open this folder as a new project in your IDE to get started."
    ))
  }

  cli::cat_rule("Copying package skeleton")

  from <- system.file("template_pti", package = "devPTIpack")

  fs::dir_copy(path = from, new_path = path, overwrite = TRUE)

  cli::cat_bullet("Copied app skeleton")
  cli::cat_rule("Setting the default config")

  cli::cat_bullet("Configured app")
  if (open && rstudioapi::hasFun("openProject")) {
    rstudioapi::openProject(path = path)
  }

  return(invisible(fs::path_abs(path)))

}
