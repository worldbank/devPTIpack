# Plot administrative boundary layers by level

Creates a faceted \`ggplot2\` map from a named list of \`sf\` layers,
with one panel for each administrative level and an optional highlighted
level.

## Usage

``` r
pti_plot_boundaries(shp_dta, highlight_level = NULL)
```

## Arguments

- shp_dta:

  A named list of \`sf\` objects, one per administrative level.

- highlight_level:

  Optional character scalar naming the level in \`shp_dta\` to fill with
  the highlight colour.

## Value

A \`ggplot\` object with one facet per administrative level.

## See also

Other pti-report:
[`pti_plot_histogram()`](https://worldbank.github.io/devPTIpack/reference/pti_plot_histogram.md),
[`pti_summary_table()`](https://worldbank.github.io/devPTIpack/reference/pti_summary_table.md)

## Examples

``` r
data(ukr_shp)
pti_plot_boundaries(ukr_shp)

pti_plot_boundaries(ukr_shp, highlight_level = "admin1_Oblast")
```
