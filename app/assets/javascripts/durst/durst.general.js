$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-search-home, #durst-image-home').removeClass('hidden'); }
 $('body').on('click', '#durst-search-home, #mapholder-link', function() {
   $('#user_util_links').find('a.active').removeClass('active');
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
     $(this).addClass('active');
   }
   $('#dhig').addClass('hidden');
   clearTimeout(dorsz);
   dorsz = setTimeout(resizedw, 100);
   $(window).trigger('resize');
map._onResize(); 
   return false;
 });

 $('body').on('click', '#durst-image-home', function() {
   $('#user_util_links').find('a.active').removeClass('active');
/*
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
     $('#mapholder-link').removeClass('hidden');
     $('#durst_osm').addClass('hidden');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
     $('#mapholder-link').addClass('hidden');
     $('#durst_osm').removeClass('hidden').attr('src', $('#durst_osm').attr('src'));
   }
*/
   if ($('#dhig').hasClass('hidden')) {
     $('#dhss,#content').addClass('hidden');
     $('#dhig').removeClass('hidden');
     $(this).addClass('active');
   } else {
     $('#content').removeClass('hidden');
       if ($('#content').hasClass('col-md-6')) {
         $('#dhss').removeClass('hidden');
       }
     $('#dhig').addClass('hidden');
   }
/*
   clearTimeout(dorsz);
   dorsz = setTimeout(resizedw, 100);
*/
   return false;
 });

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
   return false;
 });

 homeMap();
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
function homeMap() {
    //var mapurl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    //var mapurl='http://otile1.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg';
    var mapurl='http://server.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}';
    map = L.map('durst_osm').setView([40.7730, -73.8402], 11);
    L.tileLayer(mapurl, {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>. Tiles &copy; Esri&mdash;National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC.',
    maxZoom: 18
    }).addTo(map);
    marker = L.marker([40.80830, -73.96130]).addTo(map);
    marker.bindPopup('<div><h5>Avery Library</h5><address class="nomar">300 Avery<br>1172 Amsterdam Avenue<br> M.C. 0301<br> New York, NY 10027 <br>Telephone: <a href="tel:2128546199">(212) 854-6199</a><br>Email: <a href="mailto:avery@library.columbia.edu">avery@library.columbia.edu</a><div class="info-link"><a href="http://library.columbia.edu/locations/avery.html">Website</a></div></address><img style="max-height:120px;max-width:100%!important;" src="http://library.columbia.edu/content/dam/locations/avery.jpg"></div>');
    map.on('popupopen', function(e) {
      var px = map.project(e.popup._latlng);
      px.y -= e.popup._container.clientHeight/2
      map.panTo(map.unproject(px),{animate: true});
    });
}
