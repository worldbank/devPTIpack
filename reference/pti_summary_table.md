# Summarise PTI variables in a reactable table

Creates a \`reactable\` widget that summarises either compiled PTI
metadata by variable or hex-level variable coverage for a hex data
table.

## Usage

``` r
pti_summary_table(compiled_data, type = c("overview", "hex"))
```

## Arguments

- compiled_data:

  For \`type = "overview"\`, a named list returned by
  \[fct_template_reader()\] with a \`metadata\` tibble and admin-level
  tibbles. For \`type = "hex"\`, a tibble with a \`hex_id\` column and
  variable columns.

- type:

  Character scalar selecting the summary table type: \`"overview"\` or
  \`"hex"\`.

## Value

A \`reactable\` htmlwidget.

## See also

Other pti-report:
[`pti_plot_boundaries()`](https://worldbank.github.io/devPTIpack/reference/pti_plot_boundaries.md),
[`pti_plot_histogram()`](https://worldbank.github.io/devPTIpack/reference/pti_plot_histogram.md)

## Examples

``` r
if (requireNamespace("reactable", quietly = TRUE)) {
  data(ukr_mtdt_full)
  pti_summary_table(ukr_mtdt_full, type = "overview")

  hex_data <- tibble::tibble(
    hex_id  = paste0("hex_", 1:4),
    poverty = c(0.2, NA, 0.4, NA)
  )
  pti_summary_table(hex_data, type = "hex")
}

{"x":{"tag":{"name":"Reactable","attribs":{"data":[{"var_name":"poverty","non_missing_count":2,"coverage_pct":50}],"columns":[{"id":"var_name","name":"var_name","type":"character"},{"id":"non_missing_count","name":"non_missing_count","type":"numeric"},{"id":"coverage_pct","name":"coverage_pct","type":"numeric"}],"dataKey":"baadd5216a2738ab4faab1baadb12388"},"children":[]},"class":"reactR_markup"},"evals":[],"jsHooks":[]}
```
