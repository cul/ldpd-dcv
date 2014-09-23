$(function() {

 if ($('#carousel-example-generic').length) {  $('#durst-alt-home').removeClass('hide'); }
 $('body').on('click', '#durst-alt-home', function() {
   if ($('#content').hasClass('col-md-9')) {
     $('#content').removeClass('col-md-9').addClass('col-md-6');
   } else {
     $('#content').removeClass('col-md-6').addClass('col-md-9');
   }
   $('#dhss').toggleClass('hide').find('.inner').height($('#content').find('.inner').height());
   return false;
 });
});
