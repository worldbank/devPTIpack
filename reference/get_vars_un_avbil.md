# Identify (variable, admin-level) pairs with no data and no upstream coverage

Walks the indicator availability metadata and returns the admin levels
at which each indicator is missing AND cannot be back-filled from a
more-disaggregated level. Used as the first step in
\[mod_drop_inval_adm()\] to decide which admin levels must be hidden for
a given weighting.

## Usage

``` r
get_vars_un_avbil(ind_list, admin_levels = NULL)
```

## Arguments

- ind_list:

  A tibble shaped like the output of the internal indicators-list
  pipeline – at minimum a \`var_code\` column and a list-column
  \`admin_levels_years\` whose elements describe per-admin data
  presence.

- admin_levels:

  Optional character vector restricting the admin levels considered
  (e.g. \`c("admin1", "admin2")\`). Defaults to the sorted unique levels
  seen in \`ind_list\`.

## Value

A tibble with one row per unavailable \`(var_code, admin_level)\` pair.
Contains \`var_code\`, \`admin_level\`, and a logical \`any_larger\`
column (an intermediate flag carried through the pipeline; downstream
callers like \[get_min_admin_wght()\] use only \`admin_level\`).

## Note

Asymmetry pinned in PR
\[#34\](https://github.com/worldbank/devPTIpack/pull/34): the
\`lag()\`-based fill logic treats an indicator that exists only at an
earlier-sorted admin level as "available" at later-sorted levels, so
admin2 is never surfaced as unavailable for an admin1-only indicator.
The reverse direction (admin2-only -\> admin1 unavailable) works.
Candidate for the Phase 2.5 / 3.5 bug-fix sprint.

## Examples

``` r
# `ind_b` only has data at admin2 -- the function flags it as
# unavailable at admin1.
ind_list <- tibble::tibble(
  var_code = c("ind_a", "ind_b"),
  admin_levels_years = list(
    tibble::tibble(
      admin_level = c("admin1", "admin2"),
      admin_level_name = c("Oblast", "Rayon"),
      years = list(c(2020), c(2020, 2021))
    ),
    tibble::tibble(
      admin_level = "admin2",
      admin_level_name = "Rayon",
      years = list(c(2020))
    )
  )
)
get_vars_un_avbil(ind_list, admin_levels = c("admin1", "admin2"))
#> # A tibble: 1 × 3
#>   var_code admin_level any_larger
#>   <chr>    <chr>       <lgl>     
#> 1 ind_b    admin1      TRUE      
```
