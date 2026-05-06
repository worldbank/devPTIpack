# Load admin-level shape data for a PTI app

Reads a named list of \`sf\` tibbles describing administrative
boundaries at multiple levels. Resolves the source in priority order:
\`shape_dta\` (in-memory list) \> \`shape_path\` (explicit \`.rds\`
file) \> first \`.rds\` in \`shapes_fldr\` whose filename matches
\`shape_country\`.

## Usage

``` r
get_shape(shapes_fldr, shape_country, shape_path = NULL, shape_dta = NULL)
```

## Arguments

- shapes_fldr:

  Character. Directory scanned for an \`.rds\` shape file matching
  \`shape_country\` when neither \`shape_path\` nor \`shape_dta\` is
  supplied.

- shape_country:

  Character. Pattern matched against \`.rds\` filenames in
  \`shapes_fldr\`.

- shape_path:

  Character or NULL. Explicit path to a single \`.rds\` shape file.
  Takes precedence over \`shapes_fldr\`.

- shape_dta:

  List or NULL. Pre-loaded named list of \`sf\` tibbles. If supplied,
  returned unchanged.

## Value

Named list of \`sf\` tibbles, one per admin level (e.g.
\`admin0_Country\`, \`admin1_Oblast\`, \`admin2_Rayon\`,
\`admin4_Hexagon\`).

## Examples

``` r
data(ukr_shp)

# In-memory short-circuit: returns shape_dta unchanged.
shp <- get_shape(shape_dta = ukr_shp)
names(shp)
#> [1] "admin0_Country" "admin1_Oblast"  "admin2_Rayon"   "admin4_Hexagon"
```
