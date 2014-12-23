$(function() {

    // generic scrollto func
	$('#main-container').on('click', '.scrollto', function() {
	  var target = $(this).attr('href');
      var offset = $('#topnavbar').height() + 14;
	  $('html, body').animate({scrollTop:$(target).offset().top - offset }, 500, 'swing');
	  $(this).blur();
	  return false;
	});

});
