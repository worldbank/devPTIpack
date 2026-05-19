# Rwanda sample administrative boundaries

A named list of \`sf\` tibbles representing Rwanda's administrative
boundaries at three hierarchical levels. Bundled with the package as the
canonical sample geometry input for user-facing \`@examples\` across
exported functions, and the worked-example country in the Build-a-PTI
website tutorial.

## Usage

``` r
rwa_shp
```

## Format

A named list of length 3. Each element is an \`sf\` / \`tbl_df\`:

- admin0_Country:

  1 row – country polygon (Rwanda).

- admin1_Province:

  5 rows – provinces.

- admin2_District:

  30 rows – districts.

Each tibble carries the standard \`adminNPcod\` / \`adminNName\` /
\`area\` / \`geometry\` columns plus parent-level P-codes on sub-admin
layers (\`admin1_Province\` carries \`admin0Pcod\`; \`admin2_District\`
carries both \`admin0Pcod\` and \`admin1Pcod\`). The
admin1-parent-of-admin2 relationship is derived in
\`data-raw/generate-rwa-package-data.R\` via a centroid-in-polygon
spatial join.

## Source

Boundary geometries: geoBoundaries (<https://www.geoboundaries.org>)
\`gbOpen\` release for Rwanda (\`shapeISO = "RWA"\`), licensed CC-BY
4.0. See the raw GeoJSONs under \`inst/template_pti/sample-data/\`
(\`rwa_adm0.geojson\`, \`rwa_adm1.geojson\`, \`rwa_adm2.geojson\`) and
the compilation script at \`data-raw/generate-rwa-package-data.R\`.

## Details

Slot names follow the package convention \`adminN_HumanName\`. The
bundled sample uses levels 0, 1, and 2: country (1 polygon), 5
provinces, and 30 districts. Pair with \[rwa_mtdt_full\] for a working
PTI calculation.

Compared with the test-suite-oriented \[ukr_shp\]: smaller (66 vs 2,596
polygons), simpler (no synthetic admin4 hex grid), and built from a
public CC-BY 4.0 source – safe to render in tutorials and embed in
screenshots.

## See also

Other sample-data:
[`rwa_mtdt_full`](https://worldbank.github.io/devPTIpack/reference/rwa_mtdt_full.md),
[`ukr_mtdt_full`](https://worldbank.github.io/devPTIpack/reference/ukr_mtdt_full.md),
[`ukr_shp`](https://worldbank.github.io/devPTIpack/reference/ukr_shp.md)

## Examples

``` r
data(rwa_shp)
names(rwa_shp)
#> [1] "admin0_Country"  "admin1_Province" "admin2_District"
head(rwa_shp[["admin1_Province"]])
#> Simple feature collection with 5 features and 4 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 28.86171 ymin: -2.839973 xmax: 30.89908 ymax: -1.04745
#> Geodetic CRS:  WGS 84
#> # A tibble: 5 × 5
#>   admin0Pcod admin1Pcod              admin1Name   area                  geometry
#>   <chr>      <chr>                   <chr>       <dbl>             <POLYGON [°]>
#> 1 RWA        91480417B22690809677968 City of K… 7.33e8 ((30.24777 -1.845749, 30…
#> 2 RWA        91480417B18399648061901 Southern … 5.98e9 ((29.98206 -1.91296, 29.…
#> 3 RWA        91480417B74917756285357 Northern … 3.29e9 ((30.24777 -1.845749, 30…
#> 4 RWA        91480417B20985019767017 Eastern P… 9.51e9 ((30.01937 -2.074118, 30…
#> 5 RWA        91480417B44016762519517 Western P… 5.91e9 ((29.65887 -1.734995, 29…
```
