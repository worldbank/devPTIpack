# Patch an administrative metadata sheet with supplied indicator values

Rewrites one administrative sheet in a metadata workbook by validating
supplied value columns against the workbook metadata and joining those
values to the existing administrative rows by P-code.

## Usage

``` r
pti_patch_admin_sheet(
  mtdt_path = "sample-data/metadata-skeleton.xlsx",
  admin_level = "admin2_District",
  values,
  pcod_col,
  output_path = "app-data/metadata-user.xlsx"
)
```

## Arguments

- mtdt_path:

  Character. Path to the source metadata \`.xlsx\` workbook.

- admin_level:

  Character. Name of the administrative sheet to patch.

- values:

  A data frame or tibble containing the P-code column and one or more
  indicator columns whose names match \`metadata\$var_code\`.

- pcod_col:

  Character. Name of the P-code join column in \`values\`.

- output_path:

  Character. Path where the patched metadata \`.xlsx\` workbook should
  be written.

## Value

Invisibly returns \`output_path\`.

## See also

Other data-input:
[`aggregate_hex_to_shapes()`](https://worldbank.github.io/devPTIpack/reference/aggregate_hex_to_shapes.md),
[`build_hex_metadata()`](https://worldbank.github.io/devPTIpack/reference/build_hex_metadata.md),
[`fct_template_reader()`](https://worldbank.github.io/devPTIpack/reference/fct_template_reader.md),
[`fetch_hex_data()`](https://worldbank.github.io/devPTIpack/reference/fetch_hex_data.md),
[`get_available_years()`](https://worldbank.github.io/devPTIpack/reference/get_available_years.md),
[`get_shape()`](https://worldbank.github.io/devPTIpack/reference/get_shape.md),
[`list_hex_vars()`](https://worldbank.github.io/devPTIpack/reference/list_hex_vars.md),
[`make_admin_lookup()`](https://worldbank.github.io/devPTIpack/reference/make_admin_lookup.md),
[`make_hex_grid()`](https://worldbank.github.io/devPTIpack/reference/make_hex_grid.md),
[`use_hex_vars()`](https://worldbank.github.io/devPTIpack/reference/use_hex_vars.md)

## Examples

``` r
if (FALSE) { # \dontrun{
pti_patch_admin_sheet(
  mtdt_path = "sample-data/metadata-skeleton.xlsx",
  admin_level = "admin2_District",
  values = adm2_values,
  pcod_col = "admin2Pcod",
  output_path = "app-data/metadata-user.xlsx"
)
} # }
```
