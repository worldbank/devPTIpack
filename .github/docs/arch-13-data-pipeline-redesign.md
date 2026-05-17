# arch-13: Data Preparation Pipeline Redesign

**Status:** active  
**Parent tracker:** [#149](https://github.com/worldbank/devPTIpack/issues/149)  
**Runs in parallel with:** arch-12 (Space2Stats catalog expansion)  
**Schema overlap:** arch-13 §Inf-2 ([#146](https://github.com/worldbank/devPTIpack/issues/146)) mirrors `inst/hex_vars_registry.yaml` — see §4 below.

---

## §1 Context

Eduard's epic [#149](https://github.com/worldbank/devPTIpack/issues/149) redesigns the
**deployer-facing workflow** — the `inst/template_pti/` skeleton files that a user
touches when building a new country PTI from scratch. The goal: a deployer with no
existing country data can scaffold a working PTI app, load default WB boundaries, run
the full pipeline, review a data quality report, and deploy to Posit Connect with
minimal manual editing and no invisible steps.

This is a **sibling** of arch-09/arch-10 (which cover internal package plumbing —
`launch_pti()` → module chain, vignettes, pkgdown). arch-13 does not touch the Shiny
app internals; its scope is the template scaffold and the R helpers that power it.

The arch-13 track runs **in parallel** with arch-12 (Space2Stats catalog expansion).
The two tracks converge only at Step 4 (`04-hex-data.qmd`) and the shapes registry
schema — see §4.

---

## §2 Issue inventory

### Infrastructure dependencies (owned by Eduard, needed for `get_country_shapes()`)

| Issue | Short name | Scope | Can start |
|---|---|---|---|
| [#145](https://github.com/worldbank/devPTIpack/issues/145) | Inf-1 | ETL vignette — convert WB Official Boundaries to per-admin parquet | Now |
| [#146](https://github.com/worldbank/devPTIpack/issues/146) | Inf-2 | `inst/wb_shapes_registry.yaml` — bundled catalog of WB boundary parquets | Now |
| [#147](https://github.com/worldbank/devPTIpack/issues/147) | Inf-3 | `list_country_shapes()` — return tibble from registry | After #146 |
| [#148](https://github.com/worldbank/devPTIpack/issues/148) | Inf-4 | `get_country_shapes()` — fetch parquet, reconstruct sf, return package-ready list | After #145, #146, #147 |

### Setup phase

| Issue | Sub | Scope | Can start |
|---|---|---|---|
| [#152](https://github.com/worldbank/devPTIpack/issues/152) | A | `create_new_pti()` — inject `app_name` into all scaffolded files + compact next-steps CLI | After [#143](https://github.com/worldbank/devPTIpack/issues/143) (now in PR [#166](https://github.com/worldbank/devPTIpack/pull/166)) |
| [#150](https://github.com/worldbank/devPTIpack/issues/150) | B | Template: `CHECKLIST.md` with pre-run / pre-deploy checkboxes | After #152 |

### Helpers (prerequisite for all pipeline-step changes)

| Issue | Sub | Scope | Can start |
|---|---|---|---|
| [#151](https://github.com/worldbank/devPTIpack/issues/151) | C | New exported helpers: `pti_plot_boundaries()`, `pti_plot_histogram()`, `pti_summary_table()` | Now (independent) |

### Pipeline steps (all depend on C/#151 for the one-liner calls)

| Issue | Sub | Scope | Can start |
|---|---|---|---|
| [#155](https://github.com/worldbank/devPTIpack/issues/155) | D | `02a-user-zonal-stats.qmd` — explicit output contract, feed into Step 3 | Now (independent) |
| [#153](https://github.com/worldbank/devPTIpack/issues/153) | E | Rename `03-metadata.qmd` → `03-user-data.qmd`; `pti_patch_admin_sheet()` helper | After C (#151) |
| [#154](https://github.com/worldbank/devPTIpack/issues/154) | F | `04-hex-data.qmd` — remove `eval: false` guards; hex variable summary table | After C (#151) |
| [#158](https://github.com/worldbank/devPTIpack/issues/158) | G | `05-compile.qmd` — auto-detect `metadata-hex.xlsx`; `var_overrides` block; reactable summary | After C (#151) |
| [#157](https://github.com/worldbank/devPTIpack/issues/157) | H | `05-compile-report.qmd` (new) — boundary + per-variable HTML/PDF report | After C (#151) |
| [#156](https://github.com/worldbank/devPTIpack/issues/156) | I | Template: `_quarto.yml` Quarto website with sidebar nav | Now (independent) |
| [#159](https://github.com/worldbank/devPTIpack/issues/159) | J | `00-master.R` — `APP_URL` param; render full Quarto site to `docs/`; un-comment Step 04 | After C + I (#151, #156) |
| [#160](https://github.com/worldbank/devPTIpack/issues/160) | K | `06-deploy.R` — GitHub Pages deployment instructions for `docs/` | After H + I + J (#157, #156, #159) |
| [#162](https://github.com/worldbank/devPTIpack/issues/162) | L | `app.R` + `landing-page.md` — generic `{{APP_NAME}}` template | Now (independent) |

### Documentation (independent — flag for parallel work)

| Issue | Sub | Scope | Can start |
|---|---|---|---|
| [#161](https://github.com/worldbank/devPTIpack/issues/161) | Doc | Update all website tutorial vignettes (Steps 0–6) to match redesigned templates + helpers | After pipeline stable (E–J) |

### AI tooling

| Issue | Sub | Scope | Can start |
|---|---|---|---|
| [#165](https://github.com/worldbank/devPTIpack/issues/165) | P | Bundle `CLAUDE.md` + `.agents/skills/pti-data-prep/SKILL.md` with scaffolded project | After A (#152) and pipeline stable |

### Standalone issues (related but not on the #149 dependency tree)

| Issue | Sub | Scope |
|---|---|---|
| [#163](https://github.com/worldbank/devPTIpack/issues/163) | M | API coordination — `pti_patch_admin_sheet()` (#153/E) vs `generate_metadata_from_csv()` (#7) |
| [#164](https://github.com/worldbank/devPTIpack/issues/164) | N | End-to-end automated pipeline test — Rwanda + Ethiopia, fresh environment |
| [#144](https://github.com/worldbank/devPTIpack/issues/144) | — | Chore: audit and remove redundant `inst/` artifacts |

---

## §3 Dependency graph

```
#143 (bug fix) ─► #152 (A) ─► #150 (B)
                           └─► #165 (P)*

Now: #151 (C) ─► #153 (E)
             ├─► #154 (F)  ←─ arch-12 §B–E (hex registry variables)
             ├─► #158 (G)
             └─► #157 (H) ─► #160 (K)

Now: #156 (I) ─► #159 (J) ─► #160 (K)
Now: #155 (D)  (independent)
Now: #162 (L)  (independent)

Infra: #145 ─► #148 (Inf-4)
       #146 ─► #147 ─► #148
              └─► schema review vs inst/hex_vars_registry.yaml (§4)

Post-pipeline: #161 (Doc), #164 (N)
*#165 (P) also requires stable pipeline
```

**Issues that can start immediately (no blockers):** #144, #145, #146, #151, #155, #156, #162.

---

## §4 Schema overlap with arch-12

[#146](https://github.com/worldbank/devPTIpack/issues/146) (`inst/wb_shapes_registry.yaml`)
**explicitly mirrors** `inst/hex_vars_registry.yaml` — the same file Eduard designed
for the shapes catalog follows the arch-12 registry pattern.

**Shared top-level fields:**

| Field | `hex_vars_registry.yaml` (arch-12) | `wb_shapes_registry.yaml` (#146) |
|---|---|---|
| `registry_version` | `"0.1.0"` | planned |
| `base_url` / `api_root` | per-source | single `base_url` |
| `sources:` | keyed by source name | keyed by ISO-3 country code |
| `variables:` (or `admin_levels:`) | per-variable map | per-admin-level map |
| `backend:` | `"parquet"` or `"rest"` | `"parquet"` (single backend) |
| `path:` | per-source parquet URL | per-admin-level parquet path |

**Review protocol:** We leave the `wb_shapes_registry.yaml` design to Eduard (policy: "review at his PR"). When PR for #146 opens:

1. Check that top-level field names are consistent with `hex_vars_registry.yaml` (particularly `registry_version`, `backend`, `path`).
2. If Eduard's version adds a field that would benefit `hex_vars_registry.yaml` (or vice versa), raise it as a comment on the PR — not a blocker.
3. Divergences that are intentional (e.g. `admin_levels:` vs `variables:`) are fine; document them in this section once the #146 PR lands.

---

## §5 Roadmap positioning relative to arch-12

| Track | Current state | Next steps |
|---|---|---|
| arch-12 (Space2Stats catalog) | §A done (PR [#141](https://github.com/worldbank/devPTIpack/pull/141) + [#142](https://github.com/worldbank/devPTIpack/pull/142) merged); §B–E pending | YAML-only PRs for population / urbanization / NTL / built-area |
| arch-13 (pipeline redesign) | #143 bug fix in PR [#166](https://github.com/worldbank/devPTIpack/pull/166); design doc this PR | #152 (A) next after #166 merges |

The two tracks share **Step 4** (`04-hex-data.qmd`). arch-13 §F (#154) removes `eval: false` guards in Step 4 — this presupposes that the hex variables are queryable. Coordinate: land arch-12 §B (population variable) before or alongside #154 so Step 4 has at least one non-flood variable to demonstrate.

---

## §6 Definition of done (arch-13)

- [ ] `source("00-master.R")` in a freshly scaffolded Rwanda project produces: `app-data/shapes.rds`, `app-data/metadata.xlsx`, `app-data/pti-metadata.html`, `docs/index.html`.
- [ ] `shiny::runApp("app.R")` launches without error.
- [ ] All website tutorial vignettes (Steps 0–6) reflect the new file names, helper functions, and workflow.
- [ ] A freshly scaffolded project contains `CLAUDE.md` and `.agents/skills/pti-data-prep/SKILL.md`.
- [ ] End-to-end test (#164) passes for Rwanda and Ethiopia in CI.
- [ ] `R CMD check --as-cran` 0/0/0.

---

## §7 Maintenance rule

> **Any PR that changes the pipeline interface** (new helper functions, renamed files,
> new steps, changed function signatures) **must also update `CLAUDE.md` and the skill
> file** (#165). This is a hard acceptance criterion for all sub-issues.

This applies retroactively: when PR [#166](https://github.com/worldbank/devPTIpack/pull/166) (bug fix for #143) merges, the next PR for #152 must update the `{{APP_NAME}}` injection logic *and* keep the scaffolded `CLAUDE.md` consistent with the function's new behavior.
