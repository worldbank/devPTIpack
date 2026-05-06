# Validate every geometry layer in a shapes list

Iterates over \`existing_shapes\` and runs \[validate_single_geom()\] on
each layer, then performs a top-level mapping-table consistency check:
the row count of \[get_mt()\] applied to the full shapes list must equal
the row count of the most-disaggregated layer (admin levels are required
to form a strict hierarchy). Side effects only – validator messages and
a final \`testthat\` summary block.

## Usage

``` r
validate_geometries(existing_shapes)
```

## Arguments

- existing_shapes:

  Named list of \`sf\` tibbles, one per admin level. Element names must
  follow \`admin\<N\>\_\<Name\>\` (e.g. \`admin1_Oblast\`); see
  \[ukr_shp\] for the canonical shape.

## Value

Invisibly \`NULL\`. Called for side effects.

## Examples

``` r
validate_geometries(ukr_shp)
#> ℹ Checking admin0_Country
#> Test passed with 2 successes 🎊.
#> ℹ Checking admin1_Oblast
#> Test passed with 2 successes 🎊.
#> ℹ Checking admin2_Rayon
#> Test passed with 2 successes 🌈.
#> ℹ Checking admin4_Hexagon
#> Test passed with 2 successes 🎉.
#> test_that("`get_mt()` works", {...}) - Test passed with 1 success 🎊.
```
