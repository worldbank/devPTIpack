# Validate a metadata \`.xlsx\` file in isolation

Reads the metadata template at \`mtdt_path\` via
\[fct_template_reader()\] and checks two invariants: (1) the
\`metadata\` sheet has at least one row, and (2) every \`fltr\_\*\`
column is read as logical (the template rules require \`TRUE\`/\`FALSE\`
rather than \`1\`/\`0\` strings). Emits one cli alert per check; returns
the structured \`list(status, summary, issues)\` result invisibly.

## Usage

``` r
validate_read_metadata(mtdt_path, error_on_fail = TRUE)
```

## Arguments

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
validate_read_metadata("path/to/metadata.xlsx")
} # }
```
