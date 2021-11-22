$(function() {

    // generic scrollto func
	$('#main-container').on('click', '.scrollto', function() {
	  var target = $(this).attr('href');
      var offset = $('#topnavbar').height() + 14;
	  $('html, body').animate({scrollTop:$(target).offset().top - offset }, 500, 'swing');
	  $(this).blur();
	  return false;
	});
    $('#main-container').on('click', '.preview-modal', function() {
	  var url = $(this).attr('href');
      var title = $(this).attr('data-title');
      DCV.PreviewModal.show(url, title);
      return false;
    });
});

/**************
 * preview modal *
 **************/

DCV.PreviewModal = {};
DCV.PreviewModal.show = function(displayUrl, title){

  $.colorbox({
    href: displayUrl,
    maxHeight:"80%",
    maxWidth:"80%",
    opacity:".3",
    fixed:true,
    preloading: false,
    title: title
  });

  return false;
};

