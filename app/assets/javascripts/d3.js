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

window.DCV = window.DCV || function(){};
DCV.Bubbles = function(container){
  this.container = container;
  this.w = w = $(container).width() || 800;
  this.h = h = w/2.35;
  this.setRadius(0.9*(h));
};
DCV.Bubbles.searchFor = function(node) {
  if (!node.field) return false;
  var clause = 'f%5B' + node.field + '%5D%5B%5D=' + encodeURIComponent(node.name);
  if (node.parent && node.parent.field) {
    return DCV.Bubbles.searchFor(node.parent) + '&' + clause;
  } else {
    return clause;
  }
}
DCV.Bubbles.modal = function(node,link){
  var search = DCV.Bubbles.searchFor(node);
  window.console.log(search + '&limit=' + node.size);
  if (!search) {
    $(link).attr('href','/catalog');
    $(link).html("");
  } else {
    $(link).attr('href','/catalog?' + search);
    $(link).html("(show " + node.name + " items)");
  }
  d3.event.stopPropagation();
}
DCV.Bubbles.prototype = {r: null, w: 1280, h: 800, node: null, root: null}
DCV.Bubbles.prototype.setRadius = function(r) {
  this.r = r;
  this.x = d3.scale.linear().range([0, r]),
  this.y = d3.scale.linear().range([0, r]),
  this.pack = d3.layout.pack()
    .size([r, r])
    .value(function(d) { return d.size; });
}

DCV.Bubbles.prototype.draw = function(data) {
  this.root = root = data;
  this.vis = d3.select(this.container).insert("svg:svg", "h2")
  .attr("width", this.w)
  .attr("height", this.h)
  .append("svg:g")
  .attr("transform", "translate(" + (this.w - this.r) / 2 + "," + (this.h - this.r) / 2 + ")");
  var nodes = this.pack.nodes(this.root);

  var _this = this;

  this.vis.selectAll("circle")
    .data(nodes)
    .enter().append("svg:circle")
      .attr("class", function(d) { return d.children ? "parent" : "child"; })
      .attr("cx", function(d) { return d.x; })
      .attr("cy", function(d) { return d.y; })
      .attr("r", function(d) { return d.r; })
      .style("pointer-events", function(d) { return (d.depth > 1) ? "none" : "all"})
      .on("click", function(d){return (_this.node == d) ? false : _this.zoom(d);});

  this.vis.selectAll("text")
    .data(nodes).enter()
    .append("svg:text")
    .attr("class", function(d) { return d.children ? "parent" : "child"; })
    .attr("x", function(d) { return d.x; })
    .attr("y", function(d) { return d.y; })
    .attr("dy", ".35em")
    .attr("text-anchor", "middle")
    .attr("title", function(d) {return d.name;})
    .style("display","block")
    .style("overflow","hidden")
    .style("text-overflow","ellipsis")
    .style("opacity", function(d) { return d.r > 20 ? 1 : 0; })
    .style("pointer-events", function(d) { return (d.depth > 1) ? "none" : "all"})
    .style("visibility", function(d){ return d.depth != 1 ? "hidden" : "visible"; })
    .text(function(d) { return d.name; })
    .on("click", function(d){DCV.Bubbles.modal(d, $(_this.container).children('.zoom-label').children('a'));});

  d3.select(this.container).on("click", function() {return _this.zoom(root)});
  $(this.container).children('.zoom-label').html(this.root.name + " <a rel=\"catalog\" href=\"\"></a>");
}
DCV.Bubbles.prototype.chart = function(dataUrl) {
  var drawer = this;
  var func = function(data) {
    drawer.draw(data);
  }
  d3.json(dataUrl,func);
}
DCV.Bubbles.prototype.titleChain = function(d) {
  return (d.parent != null) ? this.titleChain(d.parent) + ' > ' + d.name : d.name;
}

DCV.Bubbles.prototype.zoom = function(d, i) {
  if (!d) window.console.log('no node passed to zoom');
  d = d || this.root;
  var k = this.r / d.r / 2;
  var depth = d.depth || 0;
  var x  = this.x;
  var y  = this.y;
  x.domain([d.x - d.r, d.x + d.r]);
  y.domain([d.y - d.r, d.y + d.r]);

  var node = d;
  var unhide = function(d){
    if (d.parent == node.parent && d != node) return true;
    if (d.parent == node) return true;
    if (d == node && !d.children) return true;
    return false;
  }

  var t = this.vis.transition()
      .duration(d3.event.altKey ? 7500 : 750);

  t.selectAll("circle")
      .attr("cx", function(d) { return x(d.x); })
      .attr("cy", function(d) { return y(d.y); })
      .attr("r", function(d) { return k * d.r; })
      .style("pointer-events", function(d){return (unhide(d) || d == node.parent) ? "all" : "none"});

  t.selectAll("text")
    .attr("x", function(d) { return x(d.x); })
    .attr("y", function(d) { return y(d.y); })
    .style("opacity", function(d) { return k * d.r > 20 ? 1 : 0; })
    .style("visibility",
      function(d){
        return unhide(d) ? "visible" : "hidden";
       }
    )
    .style("pointer-events", function(d){return(unhide(d) && (k*d.r > 20)) ? "all" : "none"});

  $(this.container).children('.zoom-label').html(this.titleChain(node) + " <a rel=\"catalog\" href=\"\"></a>");
  DCV.Bubbles.modal(node, $(this.container).children('.zoom-label').children('a'));
  d3.event.stopPropagation();
}
