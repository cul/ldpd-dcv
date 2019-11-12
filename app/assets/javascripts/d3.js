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
DCV.panelContentDimensions = function(container) {
  var win_width = $(window).width();
  var win_height = $(window).height();
  var win_ratio =  win_width/win_height;
  var w = $(container).width() || 800;
  var h = (win_ratio > 1.2) ?  0.9 * (w/2.35) : Math.max(Math.floor(0.75*win_height), 0.8*w);
  return [w, h];
}
DCV.Bubbles = function(container){
  this.container = container;
  var dims = DCV.panelContentDimensions(container);
  this.w = dims[0];
  this.h = dims[1];
  this.setRadius(Math.min(this.w, this.h));
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
  .attr("id", "bubble-box")
  .attr("width", '100%')
  .attr("height", '100%')
  .attr("viewBox", "0 0 "+this.w+" "+this.h)
  .attr("preserveAspectRatio", "xMidYMid")
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
    .attr("class", function(d) { return ((d.children ? "parent" : "child")); })
    .attr("x", function(d) { return d.x; })
    .attr("y", function(d) { return d.y; })
    .attr("text-anchor", "middle")
    .style("overflow","hidden")
    .style("opacity", function(d) { return d.r > 20 ? 1 : 0; })
    .style("pointer-events", function(d) { return (d.depth > 1) ? "none" : "all"})
    .style("visibility", function(d){ return d.depth != 1 ? "hidden" : "visible"; })
    .text(function(d) { return DCV.Bubbles.nameForRadius(d,1); })
    .style("font-size", function(d) { return Math.min(d.r, (d.r - 8) / this.getComputedTextLength() * 24) + "px"; })
    .attr("dy", ".35em")
    .on("click", function(d){DCV.Bubbles.modal(d, $(_this.container).children('.zoom-label').children('a'));});

  d3.select(this.container).on("click", function() {return _this.zoom(root)});
  $(this.container).children('.zoom-label').html(this.root.name + " <a rel=\"catalog\" href=\"\"></a>");
}
DCV.Bubbles.nameForRadius = function(d,k) {
  var limit = 40;
  if (d.name.length > limit) {
    return d.name.substring(0,limit) + "...";
  } else return d.name + ' (' + d.size +')';
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
  var unhide = function(e){
    if (e.parent == node.parent && e != node) return true;
    if (e.parent == node) return true;
    if (e == node && !e.children) return true;
    return false;
  }

  var t =  this.vis.transition().duration(d3.event.altKey ? 7500 : 750);

  t.selectAll("circle")
      .attr("cx", function(d) { return x(d.x); })
      .attr("cy", function(d) { return y(d.y); })
      .attr("r", function(d) { return k * d.r; })
      .style("pointer-events", function(d){return (unhide(d) || d == node.parent) ? "all" : "none"});

  t.selectAll("text")
    .attr("x", function(d) { return x(d.x); })
    .attr("y", function(d) { return y(d.y); })
    .text(function(d) { return DCV.Bubbles.nameForRadius(d,k); })
    .style("opacity", function(e) { return k * e.r > 20 ? 1 : 0; })
    .style("font-size","inherit")
    .style("visibility",
      function(e){
        return unhide(e) ? "visible" : "hidden";
       }
    )
    .style("pointer-events", function(e){return(unhide(e) && (e.r > 20)) ? "all" : "none"});
  this.vis.selectAll("text")
    .style("font-size", function(d) { return Math.min(k * d.r, k * (d.r - 8) / this.getComputedTextLength() * 24) + "px"; });

  $(this.container).children('.zoom-label').html(this.titleChain(node) + " <a rel=\"catalog\" href=\"\"></a>");
  DCV.Bubbles.modal(node, $(this.container).children('.zoom-label').children('a'));
  d3.event.stopPropagation();
}
