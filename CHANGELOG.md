# Change Logs

## v0.0.3

 - extend the lite base ( `@makechart/base` `lite/index.html`, no d3 ): needs `@makechart/base` >= 0.2.0
   and `@plotdb/chart` >= 3.7.0. scales / shapes / transitions use `chart.utils`, and transitions run on
   `chart.anim`, so animation can be recorded frame by frame ( `anim.manual` / `step` )
 - load `d3-geo` 3 / `d3-array` / `d3-selection` / `topojson-client` from the registry instead of d3js.org v2.
   map paths now use d3-geo 3's default rounding ( 3 digits )
 - add test cases ( `test/index.ls`, run with `npm test` via `@makechart/viewer` )


## v0.0.2

 - county click selects: a single click picks one, shift adds / removes, and clicking the only
   selected one again clears the selection — the same gesture as pie's wedges. counties that
   are not selected are dimmed
 - the original county name is kept as `_name` before the 臺 / 台 normalization, so the filter
   carries the value the data actually uses rather than the normalized one


## v0.0.1

init release
