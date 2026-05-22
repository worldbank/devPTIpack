# {{APP_NAME}} — PTI project

This is a **Project Targeting Index (PTI)** app built with the
[`devPTIpack`](https://worldbank.github.io/devPTIpack/) R package. A PTI
is a composite map that ranks sub-national administrative units against
a set of weighted indicators, to guide where programs and investments
should go. This project turns one country's boundaries + indicators into
a deployed Shiny dashboard plus a data-quality website.

This file gives an AI coding assistant the context it needs to help work
through the pipeline. An agent helping with data preparation should also
follow the `.agents/skills/pti-data-prep/` skill.

## Pipeline

The numbered files form the data-prep pipeline. `00-master.R` renders
them in order; each writes into `app-data/`, which the deployed app
reads.

| File | What it does |
| ---- | ------------ |
| `00-master.R` | Orchestrator — renders every step, then the report and the `docs/` website. Holds the `HEX_RESOLUTION`, `INCLUDE_HEX_IN_APP`, and `APP_URL` switches. |
| `01-shapes.qmd` | Load boundary GeoJSONs → attach `admin<N>Pcod` / `admin<N>Name` / `area` → `make_hex_grid()` → `make_admin_lookup()` → `validate_geometries()` → `app-data/shapes.rds`. |
| `02a-user-zonal-stats.qmd` | Optional. Raster zonal stats → a table in `sample-data/`. Not run by `00-master.R`. |
| `03-user-data.qmd` | Merge indicator tables into the metadata workbook via `pti_patch_admin_sheet()` → `app-data/metadata-user.xlsx`. |
| `04-hex-data.qmd` | Pull H3 hex-grid indicators from World Bank Space2Stats → `app-data/metadata-hex.xlsx`. Needs internet. |
| `05-compile.qmd` | `compile_pti_data()` merges all metadata → `app-data/metadata.xlsx` + `shapefiles.zip`. Holds the `var_overrides` table. |
| `05-compile-report.qmd` | Renders the data-quality report → `app-data/pti-metadata.{html,pdf}`. |
| `06-deploy.R` | Manual deployment guidance (Posit Connect + GitHub Pages). |
| `app.R` | The deployed Shiny app. Reads `app-data/`. |

Once the pipeline is understood, `source("00-master.R")` is the
everyday command. `CHECKLIST.md` is the task tracker — work through it.

## The three data objects

- **`shp_dta`** — a named list of `sf` tibbles, one per admin level,
  saved as `app-data/shapes.rds`. Slot names follow
  `admin<N>_<HumanName>` (e.g. `admin1_Province`).
- **`inp_dta`** — what `fct_template_reader()` returns from a metadata
  `.xlsx`: a named list with `general`, `metadata`, one
  `admin<N>_<Name>` data sheet per level, and an optional
  `weights_table`.
- **`app-data/metadata.xlsx`** — the canonical compiled workbook. Its
  `metadata` sheet is the indicator dictionary (`var_code`, `var_name`,
  `pillar_*`, `spatial_level`, `fltr_*`); each `admin<N>_<Name>` sheet
  holds wide indicator values.

## Naming convention — the #1 source of confusion

Every layer and data sheet is named `admin<N>_<HumanName>`. Each carries:

- `admin<N>Pcod` — unique polygon code; the join key.
- `admin<N>Name` — human-readable name.
- parent `admin<k>Pcod` for every `k < N` — the cascade.

`<HumanName>` is a single word, no spaces or colons. `<N>` is a digit
0–9 and need not be contiguous — `admin9_Hexagon` is the H3 hex layer.

## Never edit data by hand

Do **not** hand-edit `metadata-user.xlsx`, `metadata-hex.xlsx`,
`metadata.xlsx`, or anything under `app-data/` — Steps 3, 4 and 5
regenerate those files and silently overwrite manual edits. Instead:

- Indicator **values** → `pti_patch_admin_sheet()` in Step 3.
- PTI / Data-Explorer **inclusion flags** → the `var_overrides` table in
  `05-compile.qmd` (Step 5).

## Key `devPTIpack` functions

| Function | One-liner |
| -------- | --------- |
| `make_hex_grid()` | Build the `admin9_Hexagon` H3 grid for a country layer. |
| `make_admin_lookup()` | Populate parent `admin<k>Pcod` columns across all layers. |
| `validate_geometries()` | Structural check of the `shp_dta` list. |
| `validate_metadata()` | Check a metadata workbook against `shapes.rds`. |
| `pti_patch_admin_sheet()` | Merge a value table into one admin sheet of the workbook. |
| `fct_template_reader()` | Read a metadata `.xlsx` into the `inp_dta` list. |
| `compile_pti_data()` | Merge metadata + validate + write the deployment artefacts. |
| `pti_summary_table()` | Bird's-eye table of every compiled indicator. |
| `pti_plot_boundaries()` / `pti_plot_choropleth()` / `pti_plot_histogram()` | Static plots used by the data-quality report. |
| `launch_pti()` | Launch the Shiny dashboard locally. |

Hex pipeline (Step 4): `list_hex_vars()`, `use_hex_vars()`,
`fetch_hex_data()`, `aggregate_hex_to_shapes()`, `build_hex_metadata()`.

## More

- Task tracker: `CHECKLIST.md`.
- Step-by-step tutorials and the full column-by-column data contract:
  <https://worldbank.github.io/devPTIpack/>.
