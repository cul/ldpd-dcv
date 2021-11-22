export const durstReady = function() {

 $('body').on('click', '#format_filter input', function(e) {
   e.stopPropagation();
 });
 var oph = $('#q').attr('placeholder');
 $('body').on('change', '#format_filter input', function(e) {
    var nph = $('#format_filter input:checkbox:checked').map(function() {
      return $(this).closest('li').text();
    }).get();
	if ( nph.length > 0 ) {
	  $('#q').attr('placeholder', 'Search'+nph);
	} else {
	  $('#q').attr('placeholder', oph);
	}
 });
 $('body').on('click', '.durst-carousel-img-holder', function() {
   window.location = $('#portrait-carousel').attr('data-format-search-url');
 });
 if ($('#durst-home-carousel-wrapper').height() > 0) {
   $('.carousel-control').removeClass('hidden');
   $('#durst-home-carousel-wrapper').find('.inner img, .inner div').height($('#durst-map-image').height());
 }
}; //ready

export const scrollToBottomOfPage = function(){
	$('html, body').animate({
		scrollTop: $(document).height()-$(window).height()},
		1400,
		"easeOutQuint"
 );
};

// Resize the Durst home page carousel to match the height of the central image to the left of it
window.onresize = function(){
  // In order to stop resize events from rapidly piling up and slowing down
  // the browser, clear previously set timeout every time we get a resize event,
  // and then create a new timeout.
  if(typeof(window.durstHomeCarouselResizeTimeout) != 'undefined') {
    clearTimeout(window.durstHomeCarouselResizeTimeout);
  }
  window.durstHomeCarouselResizeTimeout = setTimeout(function(){
     if ($('#durst-home-carousel-wrapper').height() > 0) {
       $('#durst-home-carousel-wrapper').find('.inner img, .inner div').height($('#durst-map-image').height());
     }
  }, 100);
};
