# Plot a histogram for a PTI variable

Builds a histogram for a named variable in a data frame or \`sf\`
object, with optional dashed vertical lines marking requested
percentiles.

## Usage

``` r
pti_plot_histogram(
  data,
  var,
  bins = 30,
  percentiles = c(0.1, 0.25, 0.5, 0.75, 0.9)
)
```

## Arguments

- data:

  A data frame, tibble, or \`sf\` object containing \`var\`.

- var:

  Character scalar naming the column to plot.

- bins:

  Number of histogram bins to draw.

- percentiles:

  Numeric vector of probabilities passed to \[stats::quantile()\], or
  \`NULL\` to omit percentile lines.

## Value

A \`ggplot\` histogram object.

## See also

Other pti-report:
[`pti_plot_boundaries()`](https://worldbank.github.io/devPTIpack/reference/pti_plot_boundaries.md),
[`pti_summary_table()`](https://worldbank.github.io/devPTIpack/reference/pti_summary_table.md)

## Examples

``` r
data(ukr_mtdt_full)
pti_plot_histogram(ukr_mtdt_full$admin1_Oblast, "var_nval3_skewd_adm1")

pti_plot_histogram(
  ukr_mtdt_full$admin1_Oblast,
  "var_nval3_skewd_adm1",
  percentiles = NULL
)
```
