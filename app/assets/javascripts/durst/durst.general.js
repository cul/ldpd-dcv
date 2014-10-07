$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-search-home, #durst-image-home').removeClass('hide'); }
 $('body').on('click', '#durst-search-home, #mapholder-link', function() {
   $('#content,#dhss').removeClass('hide');
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
     $('#mapholder-link').removeClass('hide');
     $('#durst_osm').addClass('hide');
     $('#dhss').removeClass('hide');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
     $('#mapholder-link').addClass('hide');
     $('#durst_osm').removeClass('hide').attr('src', $('#durst_osm').attr('src'));
     $('#dhss').addClass('hide');
   }
   $('#dhig').addClass('hide');
   clearTimeout(dorsz);
   dorsz = setTimeout(resizedw, 100);
   return false;
 });

 $('body').on('click', '#durst-image-home', function() {
/*
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
     $('#mapholder-link').removeClass('hide');
     $('#durst_osm').addClass('hide');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
     $('#mapholder-link').addClass('hide');
     $('#durst_osm').removeClass('hide').attr('src', $('#durst_osm').attr('src'));
   }
*/
   if ($('#dhig').hasClass('hide')) {
     $('#dhss,#content').addClass('hide');
     $('#dhig').removeClass('hide');
   } else {
     $('#content').removeClass('hide');
       if ($('#content').hasClass('col-md-6')) {
         $('#dhss').removeClass('hide');
       }
     $('#dhig').addClass('hide');
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
     isFullWidth = true;
   } else {
     $('.container-fluid').removeClass('container-fluid').addClass('container').css('width','');
     isFullWidth = false;
   }
     $('span',this).toggleClass('glyphicon-resize-small');
   $(window).trigger('resize');
   return false;
 });

});
$(window).load(function() {
   if ($('#dhss').height() > 0) {
     $('#dhss').find('.inner img, .inner div').height($('#content .inner img').height());
     $('#durst_osm').height($('#content .inner img').height());
   }
});

function resizedw(){
    // Haven't resized in 100ms!
   if ($('#dhss').height() > 0) {
     $('#dhss').find('.inner img, .inner div').height($('#content .inner img').height());
     $('#durst_osm').height($('#content .inner img').height());
   }
}
var dorsz;
window.onresize = function(){
  clearTimeout(dorsz);
  dorsz = setTimeout(resizedw, 100);
};
