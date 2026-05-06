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

## Note

Issue \[#7\](https://github.com/worldbank/devPTIpack/issues/7) is
pinned: when the shapes file is "perfect" (no extra admin codes), the
internal \`str_c(extra_level, collapse = "\|")\` produces an
empty-pattern \`str_detect\` call that errors. Fix is part of the
broader runtime-\`test_that\` refactor.

## Examples

``` r
if (FALSE) { # \dontrun{
validate_read_shp("path/to/shapes.rds")
} # }
```
