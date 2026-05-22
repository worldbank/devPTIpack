# Step 6 -- Deployment script.
#
# Run manually when you are ready to publish your app. NOT sourced by
# 00-master.R.
#
# What gets deployed:
#   app.R               -- Shiny app entry point
#   landing-page.md     -- landing-page text
#   app-data/           -- compiled deployment data (shapes.rds, metadata.xlsx,
#                          pti-metadata.pdf, shapefiles.zip)
#
# Nothing else ships -- the docs/, sample-data/, data-raw/, and *.qmd files
# are excluded.
#
# Targets:
#   - WB Posit Connect (internal): requires VPN / WB network access.
#     Talk to the GeoPov team or your WB IT contact for an account on
#     `https://w0lxopshyprdap01.worldbank.org/` (or the appropriate
#     Connect server). Once you have an account, point RStudio /
#     Positron at it via Tools -> Global Options -> Publishing
#     -> Connect.
#   - Public-facing WB Posit Connect or shinyapps.io for external
#     audiences. shinyapps.io has a free tier that works well for
#     small public PTI apps.
#
# UI deployment (RStudio): use the blue "Publish" button in the
# upper-right corner of `app.R`. RStudio reads the manifest below, so
# `appFiles` is honoured and `app-data/` ships intact.
#
# UI deployment (Positron): same flow via the Publish command in the
# command palette.

# rsconnect::deployApp(
#   appDir   = ".",
#   appFiles = c("app.R", "landing-page.md", "app-data"),
#   appName  = basename(getwd()),
#   server   = NULL                       # set to your Connect server
# )

# Post-deployment (Posit Connect):
#   - Set viewer permissions on Posit Connect so colleagues can access
#     the app.

# -- Publish the data-quality website to GitHub Pages ------------------
#
# `source("00-master.R")` renders the data-quality website into `docs/`.
# Publish that folder to GitHub Pages so collaborators and reviewers can
# browse the data-quality report without running the pipeline locally.
# `docs/` is excluded from the Connect bundle by design -- the app and
# the website are deployed independently.
#
# One-time setup (run once per project):
#   usethis::use_github_pages(branch = "main", path = "/docs")
#
# After each pipeline run:
#   git add docs/
#   git commit -m "chore: update data-quality website"
#   git push
#
# GitHub re-deploys Pages automatically on every push to `main`.
# Your website will be at: https://<org>.github.io/<repo>/
#
# IMPORTANT: review whether `docs/` should be tracked in git at all.
# It contains rendered HTML built from your data -- consider whether
# that is appropriate for your data sensitivity and repository
# visibility before committing it.

# See https://worldbank.github.io/devPTIpack/articles/build-pti-6-deploy.html
# for the full deployment walkthrough.
