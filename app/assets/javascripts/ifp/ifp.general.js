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


DCV.SearchResults.setSearchMode = function(searchMode) {
  $('.result-type-button').removeClass('btn-success').addClass('btn-default');

  if (searchMode == 'grid') {
      $('#content .document').removeClass('col-sm-12').removeClass('list-view');
      $('#content .document').find('h3').addClass('ellipsis');
      $('#content .document .tombstone').removeClass('row');
      $('#content .document .thumbnail').removeClass('col-sm-1');
      $('#content .index-show-list-fields').addClass('hidden');
      $('#content .index-show-tombstone-fields').removeClass('hidden');
      $('#grid-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'grid', 1);
  } else if (searchMode == 'list') {
      $('#content .document').addClass('col-sm-12').addClass('list-view');
      $('#content .document').find('h3').removeClass('ellipsis');
      $('#content .document .thumbnail').addClass('col-sm-1');
      $('#content .index-show-tombstone-fields').addClass('hidden');
      $('#content .index-show-list-fields').removeClass('hidden');
      $('#list-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'list', 1);
  } else {
    //alert('Invalid search mode: ' + searchMode);
  }
}
