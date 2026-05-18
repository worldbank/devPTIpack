# {{APP_NAME}} — Setup checklist

## Before first run

- [ ] Replace `sample-data/` GeoJSONs with your country's boundaries, OR use `get_country_shapes("ISO3")` in `01-shapes.qmd`
- [ ] Update slot names and column renames in `01-shapes.qmd` to match your data
- [ ] Add your indicator workbook to `sample-data/` and point `03-user-data.qmd` at it
- [ ] Review hex variable selection in `04-hex-data.qmd` — add or remove variables as needed
- [ ] (Optional) Run `02a-user-zonal-stats.qmd` if you need raster-derived indicators
- [ ] Run `source("00-master.R")` — compiles all data into `app-data/`
- [ ] Open `docs/index.html` to review the data quality website
- [ ] Run `shiny::runApp("app.R")` to preview the app locally

## Before deployment

- [ ] Edit `landing-page.md` — replace placeholder text with your app's description
- [ ] Set `app_name` in `app.R` to confirm the correct display name
- [ ] Set `APP_URL` in `00-master.R` once you know your Posit Connect URL
- [ ] Re-run `source("00-master.R")` to regenerate the website with the live App URL
- [ ] Run `source("06-deploy.R")` to publish to Posit Connect
- [ ] Run `usethis::use_github_pages(branch = "main", path = "/docs")` to publish the data quality website
