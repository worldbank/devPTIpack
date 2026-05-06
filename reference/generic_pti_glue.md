# Default glue template for PTI map popups

Returns the package's default hover-popup template string used by
\[label_generic_pti()\]. Three lines, combining \`spatial_name\`,
\`pti_name\` (weighting scheme), and a 5-decimal \`pti_score\`. Users
can copy/modify this as a starting point for custom popups.

## Usage

``` r
generic_pti_glue()
```

## Value

A length-1 character string with glue placeholders for \`spatial_name\`,
\`pti_name\`, and \`pti_score\`.

## Examples

``` r
generic_pti_glue()
#> [1] "<strong>{spatial_name}</strong><br/>Weighting scheme: <strong>{ifelse(is.na(pti_name), 'No data', pti_name)}</strong><br/>PTI score: <strong>{ifelse(is.na(pti_score), 'No data', scales::label_number(accuracy = 0.00001)(pti_score))}</strong><br/>"
```
