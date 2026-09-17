module.exports =
  pkg:
    name: 'taiwan-map', version: '0.0.1'
    extend: {name: "@makechart/base"}
    dependencies: [
      {url: "https://d3js.org/topojson.v2.min.js", async: false}
      {url: "https://d3js.org/d3-geo.v2.min.js", async: false}
    ]
  init: ({root, ctx, pubsub, data, manager}) ->
    mod {ctx, data, manager, cls: @_instance.block}
      .then (m) -> pubsub.fire \init, mod: m .then ~> it.0

mod = ({ctx, data, manager, cls}) ->
  {chart, d3, ldcolor, topojson} = ctx
  <~ Promise.resolve!then _
  level = data.level or 'county'
  # we want to change libs dynamically so we have to load them here.
  libs = [
    {name: "pdmaptw", version: "main", path: "index.min.js", async: false}
    {name: "pdmaptw", version: "main", path: "#level.map.js"}
  ]
  ({pdmaptw}) <- manager.rescope.load libs, cls.context! .then _
  ({meta, topo}) <- pdmaptw.get(level).then _
  names = topo.objects.pdmaptw.geometries.map (g) ->
    <[c t v]>
      .map (n) -> g.properties[n]
      .filter -> it?
      .map -> meta.name[it]
      .join('')
  sample: ->
    pdmaptw.get(level).then ({meta, topo}) ->
      raw: names.map ->
        val: (100 * Math.random!).toFixed(2)
        name: pdmaptw.normalize it
        cat: "P#{Math.ceil(5 * Math.random!)}"
      binding:
        #color: {key: \val}
        cat: {key: \cat}
        name: {key: \name}
  config: chart.utils.config.from({
    preset: \default
    tip: \tip
  }) <<< {
    border:
      color: type: \color, default: \#fff
      width: type: \number, default: 1, min: 0, max: 100, step: 0.5
      linejoin: type: \choice, values: <[round bevel miter]>, default: \round
    legend: {} <<< chart.utils.config.preset.legend <<< {
      format: type: \format, default: '.2r'
      ticking:
        exp: type: \number, default: 0, min: -1, max: 1, step: 0.01
    }
  }
  dimension:
    name: {type: \N, name: "縣市"}
    color: {type: \R, name: "顏色/數值"}
    cat: {type: \C, name: "顏色/分類"}
  init: ->
    @tint = tint = new chart.utils.tint!
    @g = @layout.get-group \view
    @obj = new pdmaptw {root: @g, type: level}
    @scale = scale = {color: d3.interpolateTurbo}
    @legend = new chart.utils.legend do
      root: @root
      name: \legend
      layout: @layout
      shape: (d) -> d3.select(@).attr \fill, tint.get(d.key)
    @legend.on \select, ~> @bind!; @resize!; @render!
    @tip = new chart.utils.tip {
      root: @root,
      accessor: ({evt}) ~>
        if !(evt.target and data = d3.select(evt.target).datum!) => return null
        return {
          name: data.data.name
          value: (
            if @use-color =>
              if isNaN(data.data.color) => '-'
              else d3.format(@cfg.tip.format or '.2r')(data.data.color)
            else data.data.cat
          )
        }
      range: ~> return @layout.get-node \view .getBoundingClientRect!
    }
    @obj.init!then ~>
      d3.select @svg .selectAll \path .attr \opacity, 0
      @obj.fit {node: @g, box: @layout.get-node(\view).getBoundingClientRect!}

  # 宣告這張圖自己會發 filter. 縣市點選跟 pie 的 wedge 點選是同一種東西.
  filter: (filters, internal) ->


  parse: ->
    @tint.reset!
    @extent = c: [undefined, undefined]
    prefix = (level or '').split('/')[* - 1] or ''
    d3.select @svg .selectAll \path .each (d,i) ~>
      d.data = @data.filter(->
        # 名字要正規化才對得上地圖 ( 臺 / 台 ), 但對外發 filter 要用原本的值,
        # 所以先留一份 _name
        if !(it._name?) => it._name = (if it.name? => it.name else '')
        it.name = it._name.replace /臺/g,'台'
        it.name == d.properties.name or "#prefix#{it.name}" == d.properties.name
      ).0 or {name: d.properties.name}
      if !(@extent.c.0?) or d.data.color < @extent.c.0 => @extent.c.0 = d.data.color
      if !(@extent.c.1?) or d.data.color > @extent.c.1 => @extent.c.1 = d.data.color
    @legend.config(@cfg.legend)

  resize: ->
    @root.querySelector('.pdl-layout').classList.toggle \legend-bottom, (@cfg.legend.position == \bottom)
    @legend.update false
    @tip.toggle(if @cfg.{}tip.enabled? => @cfg.tip.enabled else true)
    @obj.fit @layout.get-box \view
    pal = if @cfg.palette => @cfg.palette.colors else <[#f00 #999 #00f]>
    len = pal.length

    @use-color = @binding.color?

    if @use-color =>
      unit = (if @binding.color.unit => that else '')
      try
        format = d3.format(@cfg.legend.format or '.2f')
      catch e
        format = d3.format('.1f')

      {ticks, extent, labels} = chart.utils.tick do
        extent: @extent.c
        len: len
        legend: {range: true, format, unit}
        exp: (@cfg.legend.ticking or {}).exp or 0

      @tint.mode chart.utils.tint.mode.ranges
      @tint.extent ticks
      @legend.data labels
    else if @binding.cat =>
      @tint.mode chart.utils.tint.mode.ordinal
      ticks = Array.from(new Set(@data.map -> it.cat)).map -> {key: it, text: it}
      @legend.data ticks
    @tint.set @cfg.palette

    @obj.fit {node: @g, box: @layout.get-box(\view)}

  render: ->
    if !@obj.scale => return
    self = @
    picked-of = (d) ~> @local.picked-of d
    d3.select @svg .selectAll \path
      .on \click, (e, d) ->
        # mod 自己的工具方法放在 mod.local, 核心建構時綁到實例上
        self.local.toggle-select e, (d3.select(@).datum! or d)
      .style \cursor, \pointer
    d3.select @svg .selectAll \path
      .transition!duration 350
      .attr \fill, (d,i) ~>
        if @use-color =>
          if !@extent.c.0? => return '#fff'
          @tint.get d.data.color
        else @tint.get d.data.cat
      .attr \opacity, (d,i) ~>
        op = picked-of d
        if @use-color =>
          if @legend.is-selected d.data.color => op else op * 0.1
        else if @legend.is-selected d.data.cat => op
        else op * 0.1
      .attr \fill-opacity, (d,i) ~>
        if @use-color =>
          if !@extent.c.0? => return 0
          if @cfg.dim-empty => (if d.data.color? => 1 else 0.2) else 1
        else
          if @cfg.dim-empty => (if d.data.cat? => 1 else 0.2) else 1
      .attr \stroke, @cfg.border.color
      .attr \stroke-width, (@cfg.border.width / @obj.scale!)
      .attr \stroke-linejoin, (@cfg.border.linejoin)
    @legend.render!

  # 這張圖自己的工具方法. `local` 是核心保留給圖表的位置, 核心不管裡面有什麼,
  # 建構時會綁到實例上, 所以呼叫端寫 `@local.xxx()` 就好
  local:

    # 單擊只選這一個, shift 增刪, 再點一次選到只剩自己的那個就清空 ( 與 pie 一致 )
    toggle-select: (evt, d) ->
      key = (d.data or {})._name
      if !key? => return
      vs = (((@binding.name or {}).filter or {}).value or []).slice!
      vs = if evt and evt.shiftKey =>
        if key in vs => vs.filter (-> it != key) else vs ++ [key]
      else if vs.length == 1 and vs.0 == key => []
      else [key]
      @filter {name: (if vs.length => {type: \index, value: vs} else undefined)}, true

    # 這一塊有沒有被選中. f 是 [] 表示「什麼都沒選」, 跟「沒有篩選」不一樣
    picked-of: (d) ->
      f = ((@binding.name or {}).filter or {}).value
      if !f => return 1
      if ((d.data or {})._name) in f => 1
      else (((@cfg.common or {}).subset or {}).opacity ? 0.2)
