# Reshape weight schemes into a single export tibble

Joins each weight scheme's \`(var_code, weight)\` tibble onto the
indicator dictionary (\`var_code\`, \`var_name\`, \`pillar_name\`),
relabelling the weight column to \`"Weights - \<scheme\>"\`. Reduces all
schemes to a single wide tibble keyed by indicator, then drops
\`var_code\` and renames the dictionary columns to user-facing headers.

## Usage

``` r
get_pti_weights_export(wghts_dta, indic_dta)
```

## Arguments

- wghts_dta:

  Named list of weight tibbles, one per scheme. Each element a tibble
  with \`var_code\` and \`weight\`.

- indic_dta:

  The indicator dictionary tibble (with \`var_code\`, \`var_name\`,
  \`pillar_name\`).

## Value

A tibble with \`Variable name\`, \`Pillar\`, and one \`Weights -
\<scheme\>\` column per scheme.

## Examples

``` r
data(ukr_mtdt_full)
weights <- get_rand_weights(ukr_mtdt_full$metadata)
get_pti_weights_export(weights, ukr_mtdt_full$metadata)
#> # A tibble: 9 × 4
#>   `Variable name`              Pillar  `Weights - wlefo 1` `Weights - ombwk 2`
#>   <chr>                        <chr>                 <dbl>               <dbl>
#> 1 var_nval3_skewd_adm1         Pilar 1                  -1                   1
#> 2 var_nval6_na_adm12           Pilar 1                   1                  -1
#> 3 var_nval15_small_skewd_adm12 Pilar 1                   1                   2
#> 4 var_nvalinf_skewd_adm2       Pilar 1                   1                   1
#> 5 var_nval60_na_adm4           Pilar 1                  -1                  -2
#> 6 var_nval4_small_skewd_adm4   Pilar 1                  -2                   0
#> 7 var_nvalinf_norm_adm24       Pilar 1                  -1                   1
#> 8 var_nvalinf_unif_adm124      Pilar 1                   0                   1
#> 9 var_nvalinf_huge_unif_adm24  Pilar 1                  -1                  -2
```
