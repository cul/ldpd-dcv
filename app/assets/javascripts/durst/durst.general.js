$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-alt-home').removeClass('hide'); }
 $('body').on('click', '#durst-alt-home, #mapholder-link', function() {
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
   return false;
 });
});
$(window).load(function() {
   $('#dhss').find('.inner img').height($('#content .inner img').height());
});

function resizedw(){
    // Haven't resized in 100ms!
   $('#dhss').find('.inner img').height($('#content .inner img').height());
}
var dorsz;
window.onresize = function(){
  clearTimeout(dorsz);
  dorsz = setTimeout(resizedw, 100);
};
