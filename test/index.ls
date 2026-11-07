# taiwan-map 的 test case ( @makechart/viewer 的 mctest )
counties = <[臺北市 新北市 桃園市 臺中市 臺南市 高雄市 基隆市 新竹市 嘉義市 新竹縣 苗栗縣 彰化縣 南投縣 雲林縣 嘉義縣 屏東縣 宜蘭縣 花蓮縣 臺東縣 澎湖縣 金門縣 連江縣]>
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n = counties.length, seed = n) ->
  rnd = mctest.random seed
  raw: counties.slice(0, n).map (name) ->
    {name, val: Math.round(rnd! * 1000) / 10, cat: "P#{Math.ceil(rnd! * 4)}"}
bycat = (n, seed) -> (mk n, seed) <<< binding: {name: {key: \name}, cat: {key: \cat}}
byval = (n, seed) -> (mk n, seed) <<< binding: {name: {key: \name}, color: {key: \val, unit: \%}}
click = (idx, shift = false) -> (c, ctx) ->
  ctx.root.querySelectorAll('path')[idx].dispatchEvent new MouseEvent(\click, {bubbles: true, shift-key: shift})

mctest.suite do
  size: [480, 480]
  data:
    cat: bycat!
    val: byval!
    part: byval 12
  cases:
    * name: "cat", data: \cat
    * name: "val", data: \val
    * name: "partial", data: \part
    * name: "dim-empty", data: \part, config: {dim-empty: true}
    * name: "border", data: \cat, config: {border: {color: \#000, width: 2, linejoin: \bevel}}
    * name: "legend:bottom", data: \val, config: {legend: {position: \bottom}}
    * name: "legend:format", data: \val, config: {legend: {format: '.1f', ticking: {exp: 0.5}}}
    * name: "palette", data: \val, config: {palette: {colors: <[#fee #f80 #800]>}}
    * name: "picked", data: \cat, steps: (c) -> c.filter {name: {type: \index, value: <[臺北市 高雄市]>}}
    * name: "click", data: \cat, steps: [(click 3), (click 7, true)]
    * name: "update", data: \cat, steps: (c) -> d = bycat 15, 3; c.set-raw d.raw, d.binding

# lite 版才有: anim 的 manual 時鐘拍動畫中間格
mctest.suite do
  size: [480, 480]
  data: cat: bycat!
  cases:
    * name: "anim:update-frames", data: \cat
      steps:
        * (c) -> d = bycat 15, 3; c.set-raw d.raw, d.binding
        * (c, ctx) ->
            for i from 1 to 3
              c.anim.step 100
              ctx.capture "t#{i * 100}"
