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
//= require ./freelib/openseadragon
//= require ./freelib/djtilesource
//= require ./freelib/purl
//= require ./freelib/jquery.colorbox-min
//= require ./freelib/jquery.tiny-draggable.min
//= require ./freelib/jquery.nicescroll.min

function ensureArray(_obj) {
  if( Object.prototype.toString.call( _obj ) === '[object Array]' ) {
      return _obj;
  } else {
    return [_obj];
  }
}

function init_seadragon_rft(_id, _rft, _showNav) {
  var ts = new OpenSeadragon.DjTileSource("http://iris.cul.columbia.edu:8888/view/", _rft);
  init_seadragon_tilesource(_id, ts, _showNav);
}

function init_seadragon_tilesource(_id, _ts, _showNav) {
  sources = ensureArray(_ts);
  OpenSeadragon({
    id:            "contentDiv2",
    prefixUrl:     "/openseadragon/images/",
    toolbar:       "toolbarDiv",
    springStiffness:        10,
    showReferenceStrip:     true,
    autoHideControls:       false,
    referenceStripScroll:   'vertical',
    tileSources: sources });
}

