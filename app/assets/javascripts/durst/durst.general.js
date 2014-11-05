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
var planes = [
 //['<div><h5>Avery Library</h5><address class="nomar">300 Avery<br>1172 Amsterdam Avenue<br> M.C. 0301<br> New York, NY 10027 <br>Telephone: <a href="tel:2128546199">(212) 854-6199</a><br>Email: <a href="mailto:avery@library.columbia.edu">avery@library.columbia.edu</a><div class="info-link"><a href="http://library.columbia.edu/locations/avery.html">Website</a></div></address><img style="max-height:160px;max-width:100%!important;" src="http://library.columbia.edu/content/dam/locations/avery.jpg"></div>', 40.80830, -73.96130],
 ['<h6>3 items found:</h6><div style="max-height:220px;max-width:220px;overflow:auto;"><div> <a class="thumbnail" href="/durst/ldpd:132415"><img style="height:120px;max-width:90%!important;" alt="256" class="img-square" itemprop="thumbnailUrl" src="https://repository-cache.cul.columbia.edu/images/ldpd:132415/square/256.jpg"></a> <div class="index-show-tombstone-fields"> <h5 class="ellipsis"><a href="/durst/ldpd:132415">Auditorium, Pyramid Lake Reservation, Nixon, Nevada</a> </h5> <div class="ellipsis">Lindquist, G. E. E. (Gustavus Elmer Emanuel), 1886-1967</div> </div> <div class="clearfix"></div> </div> <hr> <div> <a class="thumbnail" href="/durst/ldpd:134634"><img style="height:120px;max-width:90%!important;" alt="256" class="img-square" itemprop="thumbnailUrl" src="https://repository-cache.cul.columbia.edu/images/ldpd:134634/square/256.jpg"></a> <div class="index-show-tombstone-fields"> <h5 class="ellipsis"><a href="/durst/ldpd:134634">All Saints Episcopal Church, Rosebud Reservation, South Dakota</a></h5> <div class="ellipsis">Lindquist, G. E. E. (Gustavus Elmer Emanuel), 1886-1967</div> </div> <hr> <div> <a class="thumbnail" href="/durst/ldpd:134338"><img style="height:120px;max-width:100%!important;" alt="256" class="img-square" itemprop="thumbnailUrl" src="https://repository-cache.cul.columbia.edu/images/ldpd:134338/square/256.jpg"></a> <div class="index-show-tombstone-fields"> <h5 class="ellipsis"><a href="/durst/ldpd:134338">Alaskan Indian Girl at Chemawa School, Oregon</a> </h5> <div class="ellipsis">Lindquist, G. E. E. (Gustavus Elmer Emanuel), 1886-1967</div> </div> <div class="clearfix"></div> </div> <div class="clearfix"></div> </div>',  40.80830, -73.96130],
 ['<div style="max-width:220px;"> <a class="thumbnail" href="/durst/ldpd:134338"><img style="height:120px;max-width:100%!important;" alt="256" class="img-square" itemprop="thumbnailUrl" src="https://repository-cache.cul.columbia.edu/images/ldpd:134338/square/256.jpg"></a> <div class="index-show-tombstone-fields"> <h5 class="ellipsis"><a href="/durst/ldpd:134338">Alaskan Indian Girl at Chemawa School, Oregon</a> </h5> <div class="ellipsis">Lindquist, G. E. E. (Gustavus Elmer Emanuel), 1886-1967</div> </div> <div class="clearfix"></div> </div>', 40.81730, -73.91402],
 ['<div style="max-width:220px;"> <a class="thumbnail" href="/durst/ldpd:134634"><img style="height:120px;max-width:100%!important;" alt="256" class="img-square" itemprop="thumbnailUrl" src="https://repository-cache.cul.columbia.edu/images/ldpd:134634/square/256.jpg"></a> <div class="index-show-tombstone-fields"> <h5 class="ellipsis"><a href="/durst/ldpd:134634">All Saints Episcopal Church, Rosebud Reservation, South Dakota</a></h5> <div class="ellipsis">Lindquist, G. E. E. (Gustavus Elmer Emanuel), 1886-1967</div> </div> <div class="clearfix"></div> </div>', 40.77730, -73.90402]
]
function homeMap() {
    //'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    //'http://otile1.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg';
		//tiles = L.tileLayer('//server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {

		tiles = L.tileLayer('//{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png', {
				maxZoom: 18,
				attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>.'
			}),
		latlng = L.latLng(40.7730, -73.8402);

		map = L.map('durst_osm', {center: latlng, zoom: 11, layers: [tiles]});

		markers = L.markerClusterGroup();
		
		for (var i = 0; i < planes.length; i++) {
			var a = planes[i];
			var title = a[0];
			var marker = L.marker(new L.LatLng(a[1], a[2]), { title: title });
			marker.bindPopup(title);
			markers.addLayer(marker);
		}
		map.on('popupopen', function(e) {
		  var px = map.project(e.popup._latlng);
		  px.y -= e.popup._container.clientHeight/2
		  map.panTo(map.unproject(px),{animate: true});
		});

		map.addLayer(markers);

}
