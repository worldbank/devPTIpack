# Comparison-page UI for two side-by-side PTI maps

Returns a two-column \[shiny::fluidRow()\] in which each column hosts a
\[mod_map_pti_leaf_ui()\] container, allowing the user to compare two
weighting schemes (or admin-level renderings) on adjacent maps. Each map
gets its own namespace (\`first_leaf\` / \`second_leaf\`) so the two
instances are addressable independently from the server side.

## Usage

``` r
mod_pti_comparepage_ui(id)
```

## Arguments

- id:

  Character. Shiny module namespace ID. Wired to the matching
  \[mod_pti_comparepage_newsrv()\] call.

## Value

A \`shiny::bootstrapPage()\` containing the two-column compare layout.

## Examples

``` r
if (FALSE) { # \dontrun{
mod_pti_comparepage_ui("compare")
} # }
```
