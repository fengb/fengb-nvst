Mutiny.widgets.graph = {
  init: function(instigator, options){
    d3.json(options.url, function(error, data) {
      if (error) return console.warn(error);

      var width = options.width || instigator.offsetWidth
      var height = options.height || instigator.offsetHeight
      var svg = dimple.newSvg(instigator, width, height)
      var chart = new dimple.chart(svg, data)
      chart.setBounds(-1, 0, width + 1, height)
      chart.addCategoryAxis('x', options.xAxis)
      chart.addMeasureAxis('y', options.yAxis)
      chart.addSeries(options.series, dimple.plot.line)
      chart.draw()
    })
  }
}
