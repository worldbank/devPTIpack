# Validate a metadata \`.xlsx\` file in isolation

Reads the metadata template at \`mtdt_path\` via
\[fct_template_reader()\] and checks two invariants: (1) the
\`metadata\` sheet has at least one row, and (2) every \`fltr\_\*\`
column is read as logical (the template rules require \`TRUE\`/\`FALSE\`
rather than \`1\`/\`0\` strings). Side effects only – emits \`testthat\`
reporter output.

## Usage

``` r
validate_read_metadata(mtdt_path)
```

## Arguments

- mtdt_path:

  Character. Path to the metadata \`.xlsx\` template (the on-disk form
  of \[ukr_mtdt_full\]).

## Value

Invisibly \`NULL\`. Called for side effects.

## Examples

``` r
if (FALSE) { # \dontrun{
validate_read_metadata("path/to/metadata.xlsx")
} # }
```
