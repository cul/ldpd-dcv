$(function() {

  DCV.SearchResults.setCookieDefaults();

  // quick hack to get openseadragon height to be viewport height
  $('#zoom-content').height($(window).height()-120);
  /* rand banner img */
  /* unused for now
  var $rbi = [];
  var $ielems = $('.thumbnail img'), icount = $ielems.length;
  $ielems.each(function() {
    $rbi.push($ielems.attr('src'));
    if (!--icount) {
      ix = Math.floor($rbi.length*Math.random())
      $('#site-banner-left').css('background-image','url('+$rbi[ix]+')');
    }
  });
  */
  /* scroll to top function */
  $('body').on('click', '.totop', function() {
    $('body,html').animate({ scrollTop: 0 }, 500, 'swing');
    return false;
  });
  $('body').on('click', '.tocontent', function() {
    $('body,html').animate({ scrollTop: $('#content').offset().top - $('#topnavbar').height() }, 500, 'swing');
    return false;
  });
  $('body').on('click', '#list-mode', function() {
      DCV.SearchResults.setSearchMode('list');
  });
  $('body').on('click', '#grid-mode', function() {
    DCV.SearchResults.setSearchMode('grid');
  });

  $('body').on('click', '#date-graph-toggle', function() {
    DCV.SearchResults.toggleSearchDateGraphVisibility();
  });

  $('#search-navbar').find('.reset-btn').hover(function() {
      $('#appliedParams').find('.remove').addClass('btn-danger');
    }, function() {
      $('#appliedParams').find('.remove').removeClass('btn-danger');
  });
  $('#q').focus(function() {
    $('#search-navbar .input-group').css('box-shadow','0 0 18px #ccf');
  });
  $('#q').blur(function() {
    $('#search-navbar .input-group').css('box-shadow','none');
  });

  $('#show_file_assets_checkbox').on('change', function(){
    window.location = decodeURIComponent($(this).attr('data-new-location'));
  });
  $('#collapseDesc').on('show.bs.collapse', function(e){
    $(this).parent().find('i.more').addClass('glyphicon-chevron-down');
    $(this).parent().find('i.more').removeClass('glyphicon-chevron-right');
  })
  $('#collapseDesc').on('hide.bs.collapse', function(e){
    $(this).parent().find('i.more').removeClass('glyphicon-chevron-down');
    $(this).parent().find('i.more').addClass('glyphicon-chevron-right');
  })
  $('#toggle-metadata-control').on('click', function(e){
    $('#title-accordion').find('.accordion-toggle').trigger('click');
  });

  //Date Range Graph Setup
  //Activate date graphif cookie is set
  DCV.DateRangeGraphSelector.init();
  DCV.DateRangeSlider.init();

  // need better solution
  //$('.child-scroll').niceScroll({cursorminheight: "46", cursorcolor:"#111", cursorborder:"1px solid #ccc", autohidemode: false, cursorborderradius: "2px", cursorwidth: "8"});

  //If we're on the search result page...
  if($('#search-result-container').length > 0) {
    DCV.SearchResults.setSearchMode(readCookie(DCV.SearchResults.CookieNames.searchMode));
    DCV.SearchResults.setSearchDateGraphVisibility(readCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity));
  }

  //If we're on the home page
  if($('#search-result-container').length > 0) {
    DCV.SearchResults.setSearchMode(readCookie(DCV.SearchResults.CookieNames.searchMode));
    DCV.SearchResults.setSearchDateGraphVisibility(readCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity));
  }

});

//** CULTNBW START **/
  CULh_colorfg = '#000000'; // topnavbar foreground color. hex value. ex: #002B7F
  CULh_colorbg = '#444444'; // topnavbar background color. hex value. ex: #779BC3
  CULh_nobs = 1; // uncomment to NOT load our bootstrap javascript file and or use your own (v2.3.x required)
//** /CULTNBW END **/



/*********************
 * Search Results *
 *********************/
DCV.SearchResults = {};

DCV.SearchResults.CookieNames = {};
DCV.SearchResults.CookieNames.searchMode = 'search_mode';
DCV.SearchResults.CookieNames.searchDateGraphVisiblity = 'search_date_graph_visibility';

DCV.SearchResults.setCookieDefaults = function() {
  //Do not show date graph by default
  if (readCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity) == null) {
    createCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity, 'hide', 1);
  }
  //Start in grid mode by default
  if (readCookie(DCV.SearchResults.CookieNames.searchMode) == null) {
    createCookie(DCV.SearchResults.CookieNames.searchMode, 'grid', 1);
  }
};

DCV.SearchResults.setSearchMode = function(searchMode) {
  $('.result-type-button').removeClass('btn-success').addClass('btn-default');

  if (searchMode == 'grid') {
      $('#content .document').removeClass('col-sm-12').removeClass('list-view');
      $('#content .document').find('h3').addClass('ellipsis');
      $('#content .document .tombstone').removeClass('row');
      //$('#content .col-sm-3').find('[data-lv="lv"]').contents().unwrap();
      $('#content .document .thumbnail').removeClass('col-sm-2');
      $('#content .index-show-list-fields').addClass('hidden');
      $('#content .index-show-tombstone-fields').removeClass('hidden');
      $('#grid-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'grid', 1);
  } else if (searchMode == 'list') {
      $('#content .document').addClass('col-sm-12').addClass('list-view');
      $('#content .document').find('h3').removeClass('ellipsis');
      //$('#content .col-sm-3 .tombstone').addClass('row').wrapInner('<div data-lv="lv" class="col-sm-12" />');
      $('#content .document .thumbnail').addClass('col-sm-2');
      $('#content .index-show-tombstone-fields').addClass('hidden');
      $('#content .index-show-list-fields').removeClass('hidden');
      $('#list-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'list', 1);
  } else {
    //alert('Invalid search mode: ' + searchMode);
  }
}

DCV.SearchResults.setSearchDateGraphVisibility = function(showOrHide) {
  if (showOrHide == 'hide') {
    $('#search-results-date-graph').addClass('hidden');
    $('#date-graph-toggle').addClass('btn-default').removeClass('btn-success');
    createCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity, showOrHide, 1);
  } else {
    $('#search-results-date-graph').removeClass('hidden');
    DCV.DateRangeGraphSelector.resizeCanvas();
    $('#date-graph-toggle').addClass('btn-success').removeClass('btn-default');
    createCookie(DCV.SearchResults.CookieNames.searchDateGraphVisiblity, showOrHide, 1);
  }
}

DCV.SearchResults.toggleSearchDateGraphVisibility = function() {
  if($('#search-results-date-graph').hasClass('hidden')) {
    DCV.SearchResults.setSearchDateGraphVisibility('show');
  } else {
    DCV.SearchResults.setSearchDateGraphVisibility('hide');
  }
}

/**************
 * Proj Modal *
 **************/

DCV.ProjModal = {};
DCV.ProjModal.show = function(displayUrl, downloadUrl){

  $.colorbox({
    href: displayUrl,
    maxHeight:"90%",
    maxWidth:"90%",
    opacity:".6",
    fixed:true,
    inline:true,
    preloading: false,
    title: downloadUrl,
    onClosed: function() {
         $(displayUrl).addClass('hide');
    },
    onOpen: function() {
         $(displayUrl).removeClass('hide');
    },
    onComplete: function() {
            $.colorbox.resize();
    }
  });

  return false;
};


/**************
 * MODS Modal *
 **************/

DCV.ModsDownloadModal = {};
DCV.ModsDownloadModal.show = function(displayUrl, downloadUrl){

  $.colorbox({
    href: displayUrl,
    height:"90%",
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    title: '<a href="' + downloadUrl + '" data-no-turbolink="true"><span class="glyphicon glyphicon-download"></span> Download XML</a>'
  });

  return false;
};

/**************
 * Feedback Modal *
 **************/

DCV.FeedbackModal = {};
DCV.FeedbackModal.show = function(){

  $.colorbox({
    href: '//culwcm.cul.columbia.edu/dcv_feedback?current_page=' + encodeURIComponent(document.URL) + '&window_width=' + $(window).width() + '&window_height=' + $(window).height(),
    className: 'cul-no-colorbox-title-bar',
    height:"500px",
    width:"700px",
    maxHeight:"90%",
    maxWidth:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current: false,
    title: false
  });

  return false;
};

/******************
 * Citation Modal *
 ******************/

DCV.CitationDisplayModal = {};
DCV.CitationDisplayModal.show = function(citationDisplayUrl, modalLabel){

  $.colorbox({
    href: citationDisplayUrl,
    height:"90%",
    maxHeight:'300px',
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current:"{current} of {total}",
    title: modalLabel
  });

  return false;
};

/*********************
 * ZoomingImage Modal *
 *********************/

DCV.ZoomingImageModal = {};
DCV.ZoomingImageModal.show = function(){

  var zoomUrl = DCV.ZoomingImageModal.getCurrentZoomUrl();

  $.colorbox({
    href: zoomUrl,
    height:"90%",
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current:"{current} of {total}"
  });
  //$('#colorbox').tinyDraggable({handle:'#cboxTitle', exclude:'input, textarea, a, button, i'});

  return false;
};

DCV.ZoomingImageModal.openInNewWindow = function() {
  window.open(DCV.ZoomingImageModal.getCurrentZoomUrl());
  return false;
};

DCV.ZoomingImageModal.getCurrentZoomUrl = function() {
  var currentChild = $('#favorite-child img');
  return currentChild.attr('data-zoom-url') + '?initial_page=' + currentChild.attr('data-sequence');
}

/***********
 * COOKIES *
 ***********/

function createCookie(name, value, days) {
    var expires;

    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toGMTString();
    } else {
        expires = "";
    }
    document.cookie = escape(name) + "=" + escape(value) + expires + "; path=/";
}

function readCookie(name) {
    var nameEQ = escape(name) + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return unescape(c.substring(nameEQ.length, c.length));
    }
    return null;
}

function eraseCookie(name) {
    createCookie(name, "", -1);
}
