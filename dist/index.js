(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'taiwan-map',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: [
        {
          url: "https://d3js.org/topojson.v2.min.js",
          async: false
        }, {
          url: "https://d3js.org/d3-geo.v2.min.js",
          async: false
        }
      ]
    },
    init: function(arg$){
      var root, ctx, pubsub, data, manager;
      root = arg$.root, ctx = arg$.ctx, pubsub = arg$.pubsub, data = arg$.data, manager = arg$.manager;
      return mod({
        ctx: ctx,
        data: data,
        manager: manager,
        cls: this._instance.block
      }).then(function(m){
        return pubsub.fire('init', {
          mod: m
        }).then(function(it){
          return it[0];
        });
      });
    }
  };
  mod = function(arg$){
    var ctx, data, manager, cls, chart, d3, ldcolor, topojson;
    ctx = arg$.ctx, data = arg$.data, manager = arg$.manager, cls = arg$.cls;
    chart = ctx.chart, d3 = ctx.d3, ldcolor = ctx.ldcolor, topojson = ctx.topojson;
    return Promise.resolve().then(function(){
      var level, libs;
      level = data.level || 'county';
      libs = [
        {
          name: "pdmaptw",
          version: "main",
          path: "index.min.js",
          async: false
        }, {
          name: "pdmaptw",
          version: "main",
          path: level + ".map.js"
        }
      ];
      return manager.rescope.load(libs, cls.context()).then(function(arg$){
        var pdmaptw;
        pdmaptw = arg$.pdmaptw;
        return pdmaptw.get(level).then(function(arg$){
          var meta, topo, names, ref$, ref1$;
          meta = arg$.meta, topo = arg$.topo;
          names = topo.objects.pdmaptw.geometries.map(function(g){
            return ['c', 't', 'v'].map(function(n){
              return g.properties[n];
            }).filter(function(it){
              return it != null;
            }).map(function(it){
              return meta.name[it];
            }).join('');
          });
          return {
            sample: function(){
              return pdmaptw.get(level).then(function(arg$){
                var meta, topo;
                meta = arg$.meta, topo = arg$.topo;
                return {
                  raw: names.map(function(it){
                    return {
                      val: (100 * Math.random()).toFixed(2),
                      name: pdmaptw.normalize(it),
                      cat: "P" + Math.ceil(5 * Math.random())
                    };
                  }),
                  binding: {
                    cat: {
                      key: 'cat'
                    },
                    name: {
                      key: 'name'
                    }
                  }
                };
              });
            },
            config: (ref$ = chart.utils.config.from({
              preset: 'default',
              tip: 'tip'
            }), ref$.border = {
              color: {
                type: 'color',
                'default': '#fff'
              },
              width: {
                type: 'number',
                'default': 1,
                min: 0,
                max: 100,
                step: 0.5
              },
              linejoin: {
                type: 'choice',
                values: ['round', 'bevel', 'miter'],
                'default': 'round'
              }
            }, ref$.legend = (ref1$ = import$({}, chart.utils.config.preset.legend), ref1$.format = {
              type: 'format',
              'default': '.2r'
            }, ref1$.ticking = {
              exp: {
                type: 'number',
                'default': 0,
                min: -1,
                max: 1,
                step: 0.01
              }
            }, ref1$), ref$),
            dimension: {
              name: {
                type: 'N',
                name: "縣市"
              },
              color: {
                type: 'R',
                name: "顏色/數值"
              },
              cat: {
                type: 'C',
                name: "顏色/分類"
              }
            },
            init: function(){
              var tint, scale, this$ = this;
              this.tint = tint = new chart.utils.tint();
              this.g = this.layout.getGroup('view');
              this.obj = new pdmaptw({
                root: this.g,
                type: level
              });
              this.scale = scale = {
                color: d3.interpolateTurbo
              };
              this.legend = new chart.utils.legend({
                root: this.root,
                name: 'legend',
                layout: this.layout,
                shape: function(d){
                  return d3.select(this).attr('fill', tint.get(d.key));
                }
              });
              this.legend.on('select', function(){
                this$.bind();
                this$.resize();
                return this$.render();
              });
              this.tip = new chart.utils.tip({
                root: this.root,
                accessor: function(arg$){
                  var evt, data;
                  evt = arg$.evt;
                  if (!(evt.target && (data = d3.select(evt.target).datum()))) {
                    return null;
                  }
                  return {
                    name: data.data.name,
                    value: this$.useColor
                      ? isNaN(data.data.color)
                        ? '-'
                        : d3.format(this$.cfg.tip.format || '.2r')(data.data.color)
                      : data.data.cat
                  };
                },
                range: function(){
                  return this$.layout.getNode('view').getBoundingClientRect();
                }
              });
              return this.obj.init().then(function(){
                d3.select(this$.svg).selectAll('path').attr('opacity', 0);
                return this$.obj.fit({
                  node: this$.g,
                  box: this$.layout.getNode('view').getBoundingClientRect()
                });
              });
            },
            parse: function(){
              var prefix, ref$, this$ = this;
              this.tint.reset();
              this.extent = {
                c: [undefined, undefined]
              };
              prefix = (ref$ = (level || '').split('/'))[ref$.length - 1] || '';
              d3.select(this.svg).selectAll('path').each(function(d, i){
                d.data = this$.data.filter(function(it){
                  it.name = (it.name != null ? it.name : '').replace(/臺/g, '台');
                  return it.name === d.properties.name || prefix + "" + it.name === d.properties.name;
                })[0] || {
                  name: d.properties.name
                };
                if (!(this$.extent.c[0] != null) || d.data.color < this$.extent.c[0]) {
                  this$.extent.c[0] = d.data.color;
                }
                if (!(this$.extent.c[1] != null) || d.data.color > this$.extent.c[1]) {
                  return this$.extent.c[1] = d.data.color;
                }
              });
              return this.legend.config(this.cfg.legend);
            },
            resize: function(){
              var ref$, pal, len, unit, that, format, e, ticks, extent, labels;
              this.root.querySelector('.pdl-layout').classList.toggle('legend-bottom', this.cfg.legend.position === 'bottom');
              this.legend.update(false);
              this.tip.toggle(((ref$ = this.cfg).tip || (ref$.tip = {})).enabled != null ? this.cfg.tip.enabled : true);
              this.obj.fit(this.layout.getBox('view'));
              pal = this.cfg.palette
                ? this.cfg.palette.colors
                : ['#f00', '#999', '#00f'];
              len = pal.length;
              this.useColor = this.binding.color != null;
              if (this.useColor) {
                unit = (that = this.binding.color.unit) ? that : '';
                try {
                  format = d3.format(this.cfg.legend.format || '.2f');
                } catch (e$) {
                  e = e$;
                  format = d3.format('.1f');
                }
                ref$ = chart.utils.tick({
                  extent: this.extent.c,
                  len: len,
                  legend: {
                    range: true,
                    format: format,
                    unit: unit
                  },
                  exp: (this.cfg.legend.ticking || {}).exp || 0
                }), ticks = ref$.ticks, extent = ref$.extent, labels = ref$.labels;
                this.tint.mode(chart.utils.tint.mode.ranges);
                this.tint.extent(ticks);
                this.legend.data(labels);
              } else if (this.binding.cat) {
                this.tint.mode(chart.utils.tint.mode.ordinal);
                ticks = Array.from(new Set(this.data.map(function(it){
                  return it.cat;
                }))).map(function(it){
                  return {
                    key: it,
                    text: it
                  };
                });
                this.legend.data(ticks);
              }
              this.tint.set(this.cfg.palette);
              return this.obj.fit({
                node: this.g,
                box: this.layout.getBox('view')
              });
            },
            render: function(){
              var this$ = this;
              if (!this.obj.scale) {
                return;
              }
              d3.select(this.svg).selectAll('path').transition().duration(350).attr('fill', function(d, i){
                if (this$.useColor) {
                  if (this$.extent.c[0] == null) {
                    return '#fff';
                  }
                  return this$.tint.get(d.data.color);
                } else {
                  return this$.tint.get(d.data.cat);
                }
              }).attr('opacity', function(d, i){
                if (this$.useColor) {
                  if (this$.legend.isSelected(d.data.color)) {
                    return 1;
                  } else {
                    return 0.1;
                  }
                } else if (this$.legend.isSelected(d.data.cat)) {
                  return 1;
                } else {
                  return 0.1;
                }
              }).attr('fill-opacity', function(d, i){
                if (this$.useColor) {
                  if (this$.extent.c[0] == null) {
                    return 0;
                  }
                  if (this$.cfg.dimEmpty) {
                    if (d.data.color != null) {
                      return 1;
                    } else {
                      return 0.2;
                    }
                  } else {
                    return 1;
                  }
                } else {
                  if (this$.cfg.dimEmpty) {
                    if (d.data.cat != null) {
                      return 1;
                    } else {
                      return 0.2;
                    }
                  } else {
                    return 1;
                  }
                }
              }).attr('stroke', this.cfg.border.color).attr('stroke-width', this.cfg.border.width / this.obj.scale()).attr('stroke-linejoin', this.cfg.border.linejoin);
              return this.legend.render();
            }
          };
        });
      });
    });
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
