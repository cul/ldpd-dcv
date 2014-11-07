$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-search-home, #durst-image-home').removeClass('hidden'); }
 $('body').on('click', '#durst-search-home, #mapholder-link', function() {
   $('#content,#dhss').removeClass('hidden');
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
     $('#mapholder-link').removeClass('hidden');
     $('#durst_osm').addClass('hidden');
     $('#dhss').removeClass('hidden');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
     $('#mapholder-link').addClass('hidden');
     $('#durst_osm').removeClass('hidden').attr('src', $('#durst_osm').attr('src'));
     $('#dhss').addClass('hidden');
   }
   $('#dhig').addClass('hidden');
   clearTimeout(dorsz);
   dorsz = setTimeout(resizedw, 100);
   $(window).trigger('resize');
   map._onResize();
   activeNav();
   return false;
 });

 $('body').on('click', '.dhp-img-holder', function() {
   $('#durst-image-home').trigger('click');
 });
 $('body').on('click', '#durst-image-home', function() {
   if ($('#dhig').hasClass('hidden')) {
     $('#dhss,#content').addClass('hidden');
     $('#dhig').removeClass('hidden');
   } else {
     $('#content').removeClass('hidden');
       if ($('#content').hasClass('col-md-6')) {
         $('#dhss').removeClass('hidden');
       }
     $('#dhig').addClass('hidden');
   }
   activeNav();
   return false;
 });
function activeNav() {
    $('#user_util_links').find('a').removeClass('active').blur();
    if ($('#content').hasClass('col-md-9') && !$('#content').hasClass('hidden')) {
        $('#durst-search-home').addClass('active');
    }
    if (!$('#dhig').hasClass('hidden')) {
        $('#durst-image-home').addClass('active');
    }
}

 // full width layout switcher for dev/proto only.
 var isFullWidth = false;
 $('body').on('click', '#durst-full-width', function() {
   if (isFullWidth == false) {
     $('.container').removeClass('container').addClass('container-fluid').css('width','98%');
     $('#site-banner').parent().css('width','');
     isFullWidth = true;
   } else {
     $('.container-fluid').removeClass('container-fluid').addClass('container').css('width','');
     isFullWidth = false;
   }
     $('span',this).toggleClass('glyphicon-resize-small');
   $(window).trigger('resize');
   map._onResize();
   return false;
 });

 if ($('#durst_osm').length) {
   homeMap();
 }
}); //ready

$(window).load(function() {
   if ($('#dhss').height() > 0) {
     $('.carousel-control').removeClass('hidden');
     $('#dhss').find('.inner img, .inner div').height($('#mapholder').height());
     $('#durst_osm').height($('#mapholder').height());
   }
});

function resizedw(){
    // Haven't resized in 100ms!
   if ($('#dhss').height() > 0) {
     $('#dhss').find('.inner img, .inner div').height($('#mapholder').height());
     $('#durst_osm').height($('#mapholder').height());
   }
}
var dorsz;
window.onresize = function(){
  clearTimeout(dorsz);
  dorsz = setTimeout(resizedw, 100);
};

var map;
var marker;
var tiles;
function homeMap() {
    //'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    //'http://otile1.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg';
		//tiles = L.tileLayer('//server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {

		tiles = L.tileLayer('http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png', {
				maxZoom: 18,
				attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>.'
			}),

		latlng = L.latLng(DCV.centerLat, DCV.centerLong);

		map = L.map('durst_osm', {center: latlng, zoom: 11, layers: [tiles]});

		markers = L.markerClusterGroup({spiderfyOnMaxZoom: false});

		for (var i = 0; i < DCV.mapPlanes.length; i++) {
			var a = DCV.mapPlanes[i];
			var marker = L.marker(new L.LatLng(a['lat'], a['long']), { title: a['title'] });
			marker.bindPopup(
				'<a href="' + a['item_link'] + '" class="thumbnail"><img style="margin:0 auto;height:120px;max-width:100%!important;" src="' + a['thumbnail_url'] + '" /></a>' + '<br />' + '<a href="' + a['item_link'] + '">' + a['title'] + '</a>'
			);
			markers.addLayer(marker);
		}

		markers.on('clusterclick', function (a) {

			var maxItemsToShow = 5;

			if (map.getZoom() == map.getMaxZoom()) {
					var allItemHtml = '';
					var childMarkers = a.layer.getAllChildMarkers();

					var viewAllUrl = '/durst?utf8=✓&search_field=all_text_teim&q=&lat=' + childMarkers[0].getLatLng().lat + '&long=' + childMarkers[0].getLatLng().lng;

					allItemHtml += '<h6>' + childMarkers.length + ' items found <a class="pull-right" href="' + viewAllUrl + '">View all &raquo &nbsp;</a></h6>';
					allItemHtml += '<div style="max-height:200px;max-width:200px; overflow:auto;">'

					var numItemsToShow = childMarkers.length;
					if (childMarkers.length > maxItemsToShow) {
						numItemsToShow = maxItemsToShow;
					}

					for(var i = 0; i < numItemsToShow; i++) {
						var marker = childMarkers[i];
						allItemHtml += marker.getPopup().getContent() + '<hr />';
					}

					if (childMarkers.length > maxItemsToShow) {
						allItemHtml += '<a href="' + viewAllUrl + '">Click here to see the rest &raquo;</a><br />';
					}

					allItemHtml += '</div>';

					L.popup()
					.setLatLng(a.layer.getAllChildMarkers()[0].getLatLng())
					.setContent(allItemHtml)
					.openOn(map);
			}
		});

		map.on('popupopen', function(e) {
		  var px = map.project(e.popup._latlng);
		  px.y -= e.popup._container.clientHeight/2
		  map.panTo(map.unproject(px),{animate: true});
		});

		map.addLayer(markers);

}
