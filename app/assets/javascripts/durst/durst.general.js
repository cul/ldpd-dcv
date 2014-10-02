$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-search-home, #durst-image-home').removeClass('hide'); }
 $('body').on('click', '#durst-search-home, #mapholder-link', function() {
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
     $('#mapholder-link').removeClass('hide');
     $('#durst_osm').addClass('hide');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
     $('#mapholder-link').addClass('hide');
     $('#durst_osm').removeClass('hide').attr('src', $('#durst_osm').attr('src'));
   }
   $('#dhss').toggleClass('hide');
   clearTimeout(dorsz);
   dorsz = setTimeout(resizedw, 100);
   return false;
 });
});
$(window).load(function() {
   if ($('#dhss').height() > 0) {
     $('#dhss').find('.inner img').height($('#content .inner img').height());
     $('#durst_osm').height($('#content .inner img').height());
   }
});

function resizedw(){
    // Haven't resized in 100ms!
   if ($('#dhss').height() > 0) {
     $('#dhss').find('.inner img').height($('#content .inner img').height());
     $('#durst_osm').height($('#content .inner img').height());
   }
}
var dorsz;
window.onresize = function(){
  clearTimeout(dorsz);
  dorsz = setTimeout(resizedw, 100);
};
