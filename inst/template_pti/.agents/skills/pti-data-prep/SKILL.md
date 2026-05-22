---
name: pti-data-prep
description: Guide a deployer through preparing data for a devPTIpack PTI app — shapes, user metadata, hex indicators, compile, deploy. Use when working inside a scaffolded PTI project.
---

# Skill: pti-data-prep

Help a deployer take one country's data through the `devPTIpack`
pipeline to a working PTI dashboard. Read `CLAUDE.md` in the project
root first — it carries the domain model, the file map, and the data
schemas this skill assumes.

## When this applies

Trigger this skill when the user, inside a scaffolded PTI project, is:

- adapting the pipeline to a new country (replacing the Rwanda sample),
- working on any numbered step file (`01-shapes.qmd` … `06-deploy.R`),
- debugging shapes, metadata, hex, or compile errors,
- asking how PTI shapes / metadata / hex data should be structured.

## Workflow for a new country

1. **Shapes — `01-shapes.qmd`.** Replace `sample-data/rwa_*.geojson`
   with the country's boundaries. Rename columns to `admin<N>Pcod` /
   `admin<N>Name` / `area`, set the `admin<N>_<HumanName>` slot names,
   build the hex grid with `make_hex_grid()`, run `make_admin_lookup()`.
   Confirm `validate_geometries()` returns `status = "pass"`.
2. **User data — `03-user-data.qmd`.** Declare every indicator as a
   `var_code` in the metadata skeleton's `metadata` sheet, then merge
   value tables in with `pti_patch_admin_sheet()` — once per admin
   level. Confirm `validate_metadata()` passes.
3. **Hex data — `04-hex-data.qmd` (optional).** Browse `list_hex_vars()`,
   select with `use_hex_vars()`, then `fetch_hex_data()` →
   `aggregate_hex_to_shapes()` → `build_hex_metadata()`.
4. **Compile — `05-compile.qmd`.** Set inclusion flags in the
   `var_overrides` table, run `compile_pti_data()`, then review
   `pti_summary_table(..., type = "overview")` and the data-quality
   report (`app-data/pti-metadata.html`).
5. **Deploy — `06-deploy.R`.** Follow its commented guidance.

Work the two-phase `CHECKLIST.md` as you go — it is the task tracker.

## Common errors and fixes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| `validate_geometries()` fails on orphan children | A sub-admin polygon's parent `admin<k>Pcod` is missing or wrong | Run `make_admin_lookup()` to rebuild the cascade from polygon centroids. |
| An indicator column is silently dropped | The column is not declared as a `var_code` in the `metadata` sheet | Add the `var_code` row to the metadata skeleton, then re-patch. |
| An indicator is all `NA` after `pti_patch_admin_sheet()` | `pcod_col` values don't match the layer's `admin<N>Pcod` | Align the P-codes — the join is exact, unmatched rows become `NA`. |
| Step 4 errors when offline | `fetch_hex_data()` needs internet (World Bank Space2Stats) | Comment the `04-hex-data.qmd` line in `00-master.R`, or run Step 4 later. |
| `compile_pti_data()` warns of a duplicate `var_code` | A hex indicator and a user indicator share a column name | Rename one in its source metadata sheet for a clean result. |

## Code patterns to always use

- Plot via the helpers — `pti_plot_boundaries()`,
  `pti_plot_choropleth()`, `pti_plot_histogram()` — not raw `ggplot2`.
- Summarise indicators with `pti_summary_table()`, not hand-rolled
  tables.
- Read metadata workbooks with `fct_template_reader()`, never `readxl`
  directly, so you get the parsed `inp_dta` list shape.
- Merge indicator values with `pti_patch_admin_sheet()`.

## Never do this

- **Never** hand-edit `metadata-user.xlsx`, `metadata-hex.xlsx`,
  `metadata.xlsx`, or any file under `app-data/` — the pipeline
  regenerates them and overwrites manual edits. Use
  `pti_patch_admin_sheet()` (values) and the `var_overrides` table
  (inclusion flags) instead.
- **Never** skip `validate_geometries()` / `validate_metadata()` — a
  `pass` is the contract every later step depends on.
- **Never** patch a result by editing `app-data/` outputs — fix the
  upstream step file and re-run `source("00-master.R")`.
