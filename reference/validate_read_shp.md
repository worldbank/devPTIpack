# Validate a shapes \`.rds\` file in isolation

Reads the \`.rds\` at \`shp_path\` and checks two invariants: (1) the
object is a non-empty named list, and (2) every \`admin\<N\>Pcod\`
column referenced inside any layer has a corresponding top-level
\`admin\<N\>\_\*\` element. Side effects only – emits \`testthat\`
reporter output.

## Usage

``` r
validate_read_shp(shp_path)
```

## Arguments

- shp_path:

  Character. Path to an \`.rds\` file containing the shapes list (the
  on-disk form of objects shaped like \[ukr_shp\]).

## Value

Invisibly \`NULL\`. Called for side effects.

## Examples

``` r
if (FALSE) { # \dontrun{
validate_read_shp("path/to/shapes.rds")
} # }
```
