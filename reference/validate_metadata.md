# Verify that a shapes file and metadata file together produce valid PTI scores

End-to-end pre-flight validator for a PTI deployment. Calls
\[validate_read_shp()\] and \[validate_read_metadata()\] on the inputs,
then runs the full calculation pipeline (\[pivot_pti_dta()\] -\>
\[get_weighted_data()\] -\> \[get_scores_data()\] -\>
\[expand_adm_levels()\] -\> \[agg_pti_scores()\]) under an all-equal
weighting and asserts that the number of scored pillars matches
\`nrow(indicators_list)\`. Emits one cli alert per check; returns the
structured \`list(status, summary, issues)\` result invisibly. With
\`error_on_fail = TRUE\` (default), throws if any \`fail\`-level issue
is recorded.

## Usage

``` r
validate_metadata(shp_path, mtdt_path, error_on_fail = TRUE)
```

## Arguments

- shp_path:

  Character. Path to an \`.rds\` file containing the shapes list (the
  on-disk form of objects shaped like \[ukr_shp\]).

- mtdt_path:

  Character. Path to the metadata \`.xlsx\` template (the on-disk form
  of \[ukr_mtdt_full\]).

- error_on_fail:

  Logical. If \`TRUE\` (default), throws on any \`fail\`-level issue.
  Pass \`FALSE\` to inspect the structured result instead.

## Value

Invisibly, a list with components \`status\` (\`"pass"\`, \`"warn"\`, or
\`"fail"\`), \`summary\` (one-line string), and \`issues\` (list of
issue records).

## Examples

``` r
if (FALSE) { # \dontrun{
validate_metadata(
  shp_path  = "path/to/shapes.rds",
  mtdt_path = "path/to/metadata.xlsx"
)
} # }
```
