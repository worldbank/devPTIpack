# PTI app project

Scaffolded by `devPTIpack::create_new_pti()`. This project is a
working Rwanda PTI app -- run it as-is to see a Shiny app come up
end-to-end with sample data, then replace the Rwanda inputs with your
own country.

## File order

The numbered files form the data-prep pipeline:

| File                       | Step                                  | What it does                                                    |
| -------------------------- | ------------------------------------- | --------------------------------------------------------------- |
| `00-master.R`              | Pipeline orchestrator                 | Renders the step `.qmd` files top-to-bottom into `app-data/`.    |
| `01-shapes.qmd`            | Step 1 -- Shapefiles                  | Load + validate boundary GeoJSONs, save `app-data/shapes.rds`.   |
| `02a-user-zonal-stats.qmd` | Step 2 -- Zonal stats (optional)      | Stub. Extract raster zonal stats. Run manually if needed.       |
| `03-user-data.qmd`         | Step 3 -- User data                   | Merge indicator data into the metadata workbook via `pti_patch_admin_sheet()`, validate, stage `metadata-user.xlsx`. |
| `04-hex-data.qmd`          | Step 4 -- HEX data                    | Pull H3 hex-grid indicators from World Bank Space2Stats into `metadata-hex.xlsx`. |
| `05-compile.qmd`           | Step 5 -- Compile and finalise        | `compile_pti_data()` merges intermediates into `metadata.xlsx` + `shapefiles.zip`. |
| `05-compile-report.qmd`    | Step 5 -- Data-quality report         | Renders the per-indicator data-quality report (`pti-metadata.{html,pdf}`). |
| `06-deploy.R`              | Step 6 -- Deploy                      | Manual deployment script (Posit Connect + GitHub Pages guidance). |
| `app.R`                    | Shiny app entry point                 | The deployed app. Loads from `app-data/` paths.                  |
| `landing-page.md`          | App landing-page text                 | Markdown content shown on the app's About tab.                   |

Render the pipeline with:

```r
source("00-master.R")
```

## Tutorials

Each step `.qmd` file has a working chunk of Rwanda code at the top
and a link in the file header pointing to the corresponding website
tutorial. The tutorials live at:

- Step 0 -- Setup -- <https://worldbank.github.io/devPTIpack/articles/build-pti-0-setup.html>
- Step 1 -- Shapefiles -- <https://worldbank.github.io/devPTIpack/articles/build-pti-1-shapefiles.html>
- Step 2 -- Zonal stats (optional) -- <https://worldbank.github.io/devPTIpack/articles/build-pti-2-zonal-stats.html>
- Step 3 -- User data -- <https://worldbank.github.io/devPTIpack/articles/build-pti-3-metadata.html>
- Step 4 -- HEX data -- <https://worldbank.github.io/devPTIpack/articles/build-pti-4-hex.html>
- Step 5 -- Compile -- <https://worldbank.github.io/devPTIpack/articles/build-pti-5-compile.html>
- Step 6 -- Deploy -- <https://worldbank.github.io/devPTIpack/articles/build-pti-6-deploy.html>

## Folders

```
sample-data/   Rwanda raw inputs (GeoJSONs + synthetic indicator workbooks).
data-raw/      Seeded scripts that produced sample-data/ (re-runnable).
app-data/      Pipeline outputs. THIS IS THE FOLDER YOU DEPLOY.
docs/          Data-quality website built by Step 5 (publish to GitHub Pages).
R/             golem boilerplate.
```

## ⚠ `app-data/` and git

`app-data/` holds the deployment-ready compiled artefacts. Decide
**consciously** whether to track this folder in git:

- **Track it** if your data is non-sensitive and small enough to live
  in a repo. Useful for reproducible reviews.
- **Ignore it** (`echo "app-data/" >> .gitignore`) if the data is
  sensitive, large, or both. This is the conservative default.

Don't let it slip through unreviewed.

## Current template state

All pipeline steps ship with **working Rwanda code** that produces
real outputs into `app-data/`.

`00-master.R` renders Steps 01, 03, 04, and 05 by default, then the
data-quality report and the `docs/` website. The 02a (optional zonal
stats) line is commented and clearly marked; 06 (deploy) is always
manual.

Visual-validation app calls (`app_validate_shp()` in `01-shapes.qmd`
and `app_validate_metadata()` in `03-user-data.qmd`) are commented in
the template because `00-master.R` runs the files unattended. Uncomment
them and re-source the relevant `.qmd` interactively when you want a
visual pass over the data.
