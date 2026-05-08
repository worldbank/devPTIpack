# Package index

## Launch PTI Applications

Top-level functions for starting a PTI Shiny app or scaffolding a new
PTI project directory.

- [`launch_pti()`](https://worldbank.github.io/devPTIpack/reference/launch_pti.md)
  : Launch a multi-tab PTI Shiny app
- [`launch_pti_onepage()`](https://worldbank.github.io/devPTIpack/reference/launch_pti_onepage.md)
  : Launch a single-page PTI Shiny app
- [`create_new_pti()`](https://worldbank.github.io/devPTIpack/reference/create_new_pti.md)
  : Scaffold a new PTI app project

## PTI Calculation Pipeline

Functions that implement or support the core PTI score calculation
pipeline.
[`run_pti_pipeline()`](https://worldbank.github.io/devPTIpack/reference/run_pti_pipeline.md)
is the primary entry point for headless (non-Shiny) pipeline execution.

- [`run_pti_pipeline()`](https://worldbank.github.io/devPTIpack/reference/run_pti_pipeline.md)
  : Run the full PTI calculation pipeline
- [`label_generic_pti()`](https://worldbank.github.io/devPTIpack/reference/label_generic_pti.md)
  : Apply a glue-template \`pti_label\` column to per-admin PTI tibbles
- [`generic_pti_glue()`](https://worldbank.github.io/devPTIpack/reference/generic_pti_glue.md)
  : Default glue template for PTI map popups

## Data Input & Preparation

Read and parse the PTI metadata Excel template and retrieve processed
geometry objects.

- [`fct_template_reader()`](https://worldbank.github.io/devPTIpack/reference/fct_template_reader.md)
  : Read a PTI metadata Excel template into the package's
  list-of-tibbles format
- [`get_shape()`](https://worldbank.github.io/devPTIpack/reference/get_shape.md)
  : Load admin-level shape data for a PTI app

## Weights

Generate and manipulate indicator weight schemes used in the PTI
calculation.

- [`get_rand_weights()`](https://worldbank.github.io/devPTIpack/reference/get_rand_weights.md)
  : Generate a random list of weighting schemes
- [`get_all_weights_combs()`](https://worldbank.github.io/devPTIpack/reference/get_all_weights_combs.md)
  : Enumerate all weighting-scheme combinations of a given size
- [`get_min_admin_wght()`](https://worldbank.github.io/devPTIpack/reference/get_min_admin_wght.md)
  : Reduce per-scheme weights to the admin levels that must be hidden

## Data Export

Extract PTI scores, weight tables, and unavailable-admin summaries for
downstream reporting or download.

- [`get_pti_scores_export()`](https://worldbank.github.io/devPTIpack/reference/get_pti_scores_export.md)
  : Reshape PTI scores into per-admin-level export tibbles
- [`get_pti_weights_export()`](https://worldbank.github.io/devPTIpack/reference/get_pti_weights_export.md)
  : Reshape weight schemes into a single export tibble
- [`get_vars_un_avbil()`](https://worldbank.github.io/devPTIpack/reference/get_vars_un_avbil.md)
  : Identify (variable, admin-level) pairs with no native data

## Validation

Pre-flight validators for geometry layers, metadata templates, and data
file paths. Run these before deploying a PTI app to catch input problems
early.

- [`validate_geometries()`](https://worldbank.github.io/devPTIpack/reference/validate_geometries.md)
  : Validate every geometry layer in a shapes list
- [`validate_metadata()`](https://worldbank.github.io/devPTIpack/reference/validate_metadata.md)
  : Verify that a shapes file and metadata file together produce valid
  PTI scores
- [`validate_read_metadata()`](https://worldbank.github.io/devPTIpack/reference/validate_read_metadata.md)
  : Validate a metadata \`.xlsx\` file in isolation
- [`validate_read_shp()`](https://worldbank.github.io/devPTIpack/reference/validate_read_shp.md)
  : Validate a shapes \`.rds\` file in isolation
- [`drop_inval_adm()`](https://worldbank.github.io/devPTIpack/reference/drop_inval_adm.md)
  : Strip unplottable admin levels out of a pre-plot data structure
- [`mod_drop_inval_adm()`](https://worldbank.github.io/devPTIpack/reference/mod_drop_inval_adm.md)
  : Drop-invalid-admin module server

## Visualisation Helpers

Utility functions for plotting and labelling PTI outputs.

- [`gg_admin_list()`](https://worldbank.github.io/devPTIpack/reference/gg_admin_list.md)
  : Build a list of ggplot maps from PTI admin data

## Shiny Modules

Reusable Shiny UI and server module pairs that compose the PTI
application interface. Advanced users can embed individual modules into
custom Shiny apps.

- [`mod_ptipage_twocol_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_ptipage_twocol_ui.md)
  [`mod_ptipage_box_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_ptipage_twocol_ui.md)
  : Two-column UI for a PTI page
- [`mod_ptipage_newsrv()`](https://worldbank.github.io/devPTIpack/reference/mod_ptipage_newsrv.md)
  : Page-level PTI server module
- [`mod_pti_comparepage_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_pti_comparepage_ui.md)
  : Comparison-page UI for two side-by-side PTI maps
- [`mod_pti_comparepage_newsrv()`](https://worldbank.github.io/devPTIpack/reference/mod_pti_comparepage_newsrv.md)
  : Comparison-page server module
- [`mod_dta_explorer2_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_dta_explorer2_ui.md)
  : Data-explorer page UI
- [`mod_dta_explorer2_server()`](https://worldbank.github.io/devPTIpack/reference/mod_dta_explorer2_server.md)
  : Data-explorer page server module
- [`mod_map_pti_leaf_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_map_pti_leaf_ui.md)
  : Map container UI for PTI page modules
- [`mod_leaf_side_panel_ui()`](https://worldbank.github.io/devPTIpack/reference/mod_leaf_side_panel_ui.md)
  : Map side-panel UI for a PTI page
- [`mod_plot_pti2_srv()`](https://worldbank.github.io/devPTIpack/reference/mod_plot_pti2_srv.md)
  : Main PTI map orchestration module
- [`mod_tab_open_first_newserv()`](https://worldbank.github.io/devPTIpack/reference/mod_tab_open_first_newserv.md)
  : Tab-opening invalidator for custom PTI page layouts

## Package Utilities

Low-level golem infrastructure helpers. These are exported primarily to
support the auto-generated `app.R` in scaffolded projects.

- [`app_sys()`](https://worldbank.github.io/devPTIpack/reference/app_sys.md)
  : Resolve a path inside the installed devPTIpack package
- [`golem_add_external_resources()`](https://worldbank.github.io/devPTIpack/reference/golem_add_external_resources.md)
  : Bundle external resources for a PTI Shiny app

## Sample Data

Bundled sample datasets used in examples and the test suite. `ukr_shp`
provides Ukraine administrative boundaries; `ukr_mtdt_full` provides
matching synthetic indicator metadata.

- [`ukr_shp`](https://worldbank.github.io/devPTIpack/reference/ukr_shp.md)
  : Ukraine sample administrative boundaries
- [`ukr_mtdt_full`](https://worldbank.github.io/devPTIpack/reference/ukr_mtdt_full.md)
  : Ukraine sample PTI metadata input
