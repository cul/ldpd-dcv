// This is a manifest file that'll be compiled into freelib.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require ./d3/d3.v3.min

Dcv = window.Dcv || {}
Dcv.Bubbles = {r: null, w: 1280, h: 800, node: null, root: null}
Dcv.Bubbles.setRadius = function(r) {
  Dcv.Bubbles.r = r;
  Dcv.Bubbles.x = d3.scale.linear().range([0, r]),
  Dcv.Bubbles.y = d3.scale.linear().range([0, r]),
  Dcv.Bubbles.pack = d3.layout.pack()
    .size([r, r])
    .value(function(d) { return d.size; });
}
Dcv.Bubbles.chart = function(container, dataUrl) {
  var w = $(container).width(), h = $(container).height();

  var r = 0.9*(h || w);
  h = h || 1.1*r;
  //alert("w:" + w + ", r:" + r);
  Dcv.Bubbles.setRadius(r);
  Dcv.Bubbles.vis = d3.select(container).insert("svg:svg", "h2")
    .attr("width", w)
    .attr("height", h)
    .append("svg:g")
    .attr("transform", "translate(" + (w - r) / 2 + "," + (h - r) / 2 + ")");
  d3.json(dataUrl, function(data) {
    var node = root = data;

    var nodes = Dcv.Bubbles.pack.nodes(root);

    Dcv.Bubbles.vis.selectAll("circle")
      .data(nodes)
      .enter().append("svg:circle")
        .attr("class", function(d) { return d.children ? "parent" : "child"; })
        .attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; })
        .attr("r", function(d) { return d.r; })
        .on("click", function(d) { return (node == d) ? false : Dcv.Bubbles.zoom(d); }); // zoom(node == d ? root : d)

    Dcv.Bubbles.vis.selectAll("text")
      .data(nodes).enter()
      .append("svg:text")
      .attr("class", function(d) { return d.children ? "parent" : "child"; })
      .attr("x", function(d) { return d.x; })
      .attr("y", function(d) { return d.y; })
      .attr("dy", ".35em")
      .attr("text-anchor", "middle")
      .attr("title", function(d) {return d.name;})
      .style("overflow","hidden")
      .style("text-overflow","ellipsis")
      .style("opacity", function(d) { return d.r > 20 ? 1 : 0; })
      .style("visibility", function(d){ return d.depth > 1 ? "hidden" : "visible"; })
      .text(function(d) { return d.name; });

    d3.select(window).on("click", function() { Dcv.Bubbles.zoom(root); });
    document.getElementById('zoom-label').childNodes[0].nodeValue=(root.name);
  });
}
Dcv.Bubbles.titleChain = function(d) {
  return (d.parent != null) ? Dcv.Bubbles.titleChain(d.parent) + ' > ' + d.name : d.name;
}

Dcv.Bubbles.zoom = function(d, i) {
  var k = Dcv.Bubbles.r / d.r / 2;
  var depth = d.depth || 0;
  var x  = Dcv.Bubbles.x;
  var y  = Dcv.Bubbles.y;
  var titleChain = Dcv.Bubbles.titleChain;
  x.domain([d.x - d.r, d.x + d.r]);
  y.domain([d.y - d.r, d.y + d.r]);

  var t = Dcv.Bubbles.vis.transition()
      .duration(d3.event.altKey ? 7500 : 750);

  t.selectAll("circle")
      .attr("cx", function(d) { return x(d.x); })
      .attr("cy", function(d) { return y(d.y); })
      .attr("r", function(d) { return k * d.r; });

  var node = d;

  t.selectAll("text")
      .attr("x", function(d) { return x(d.x); })
      .attr("y", function(d) { return y(d.y); })
      .style("width", function(d){ return '' + (2*k*d.r) + 'px'; })
      .style("opacity", function(d) { return k * d.r > 20 ? 1 : 0; })
      .style("visibility", function(d){ return (d.depth == depth && d != node) || (d.parent == node) || (d == node && !d.children) ? "visible": "hidden"; });

  d3.event.stopPropagation();
  document.getElementById('zoom-label').childNodes[0].nodeValue=(titleChain(node));
}
