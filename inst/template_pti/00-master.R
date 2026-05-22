# 00-master.R -- pipeline orchestrator.
#
# Renders the step `.qmd` files top-to-bottom in their canonical order
# and then renders the full Quarto website into `docs/`. Each step
# writes its output into `app-data/`; downstream steps read from there.
# Run this script with the project root as the working directory:
#
#   source("00-master.R")
#
# Comment / uncomment the individual render lines below to skip
# optional or future steps.
#
# Step state:
#   01  Shapes              -- working (Rwanda data + validate_geometries)
#   02a Zonal stats         -- optional stub; user runs manually if needed
#   03  User data           -- working (pti_patch_admin_sheet + validate_metadata)
#   04  HEX data            -- working (live WB parquet; needs internet)
#   05  Compile             -- working (compile_pti_data merges + validates + renders)
#   05r Compile report      -- working (HTML always, PDF best-effort; -> app-data/)
#   06  Deploy              -- manual; see 06-deploy.R

# ── App URL (set after deploying to Posit Connect / shinyapps.io) ────────────
# Paste your live app URL here once the app is deployed. This populates
# the "Live app" page in the data-quality website (`app-page.qmd`).
# Leave as "" until the app is deployed.
APP_URL <- ""

# ── Hex grid configuration ───────────────────────────────────────────────────
# H3 resolution for the hex grid built in Step 1 and used throughout
# the pipeline. This is the single place that controls what resolution
# goes into the app.
#
#   5  ~252 km² per cell  -- very large countries, coarse view
#   6  ~36 km²  per cell  -- default; most country-level PTI apps
#   7  ~5 km²   per cell  -- small countries or high-detail apps
#
# Changing this after running Step 1 requires re-running Steps 1, 4,
# and 5 in sequence.
HEX_RESOLUTION <- 6L

# Set to TRUE to include hex-level polygons in the deployed app.
# When FALSE (default), hex-sourced indicators are still available at
# all admin levels -- only the hex polygons themselves are excluded.
# Recommended FALSE when the hex grid exceeds ~5,000 cells.
INCLUDE_HEX_IN_APP <- FALSE

# ── Pass deployer config to Quarto ───────────────────────────────────────────
# Each `quarto_render()` runs in a fresh R process, so the variables set
# above do not carry over on their own — export them as environment
# variables that the step `.qmd` files read back via `Sys.getenv()`.
Sys.setenv(
  PTI_APP_URL            = APP_URL,
  PTI_HEX_RESOLUTION     = HEX_RESOLUTION,
  PTI_INCLUDE_HEX_IN_APP = INCLUDE_HEX_IN_APP
)

# ── Pipeline (individual step renders) ───────────────────────────────────────
quarto::quarto_render("01-shapes.qmd")
# quarto::quarto_render("02a-user-zonal-stats.qmd")  # optional
quarto::quarto_render("03-user-data.qmd")
quarto::quarto_render("04-hex-data.qmd")             # needs internet
quarto::quarto_render("05-compile.qmd")

# ── Data-quality report -> app-data/pti-metadata.{html,pdf} ───────────────────
# HTML always; PDF is best-effort (skipped with a warning if no LaTeX
# engine is available). Both are staged into app-data/ alongside the
# other deployment artefacts.
quarto::quarto_render("05-compile-report.qmd", output_format = "html")
tryCatch(
  quarto::quarto_render("05-compile-report.qmd", output_format = "pdf"),
  error = function(e) {
    cli::cli_warn(c(
      "PDF report skipped -- {conditionMessage(e)}",
      "i" = "The HTML report was still produced; install a LaTeX \\
engine for the PDF."
    ))
  }
)
for (.ext in c("html", "pdf")) {
  .src <- paste0("05-compile-report.", .ext)
  if (file.exists(.src)) {
    file.rename(.src, file.path("app-data", paste0("pti-metadata.", .ext)))
  }
}

# ── Render the full data-quality website ─────────────────────────────────────
# Output goes to `docs/` as configured by `output-dir:` in `_quarto.yml`.
quarto::quarto_render(input = ".")

cli::cli_inform(c(
  "v" = "Pipeline complete.",
  "i" = "Open {.file docs/index.html} to review the data-quality website.",
  "i" = "Run {.run shiny::runApp('app.R')} to preview the app locally."
))

# Deployment runs manually:
# source("06-deploy.R")
