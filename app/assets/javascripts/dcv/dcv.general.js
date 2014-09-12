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

  $('body').on('click', '#unzoom-mode', function(){
     // hide the zooming stuff
      $('div#zoom-gallery').addClass('hidden');

      $('#child_items').removeClass('hidden');
      $('#zoom-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#zoom-mode', function(){
    switchToZoom();
  });
  $('body').on('click', '#inset-zoom-mode', function(){
    switchToZoom();
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

  //If we're on an item show page, load download links
  if($('#item-show').length > 0) {
    loadDownloadsForItemShowPage();
  }

});

function loadDownloadsForItemShowPage() {

  $('#item-show-downloads li.bsDownload').remove();
  $('#item-show-downloads li.bsDownload').append('<li class="placeholder"><a href="#">Loading downloads...</a></li>');

  var bsUrl = $('#favorite-child img').attr('data-bytestreams')
  loadByteStreams(bsUrl, function(data){
    $('#item-show-downloads li.placeholder').remove();
    $('#item-show-downloads').append(getListItemContentFromBytestreamsData(data));
  });
}


function getListItemContentFromBytestreamsData(data) {
  var li_html = '';
  for(var i=0;i<data.length;i++){
    dlName = data[i]["title"] + '.' + data[i]["url"].match(/\.([^.]+)$/)[1];
    dlName += ' (' + data[i]["width"] + 'x' + data[i]["length"] + ')';
    li_html += '<li class="bsDownload"><a href="' + data[i]["url"] + '" target="_blank"><span class="glyphicon glyphicon-download"></span> ' + dlName + '</a></li>'
  }
  return li_html;
}

//initialPage is an optional parameter
function initTiles(initialPage) {

  if (typeof(initialPage) != 'undefined') {
    DCV.zoomingViewerInitialPage = initialPage;
  } else {
    DCV.zoomingViewerInitialPage = 0;
  }

  if (!$.tileSources){
    $.djUrl = "http://iris.cul.columbia.edu:8888/view/";
    if ($('#zoom-gallery').attr('data-url')) {
      setTilesFromQuery($('#zoom-gallery').attr('data-url'))
    } else {
      loadByteStreams($('#zoom-gallery').attr('data-bytestreams'), setTileFromId);
    }
  } else {
    initZoomingViewer($.tileSources);
  }
}
function initZoomingViewer(tileSources) {

  if ($.zoomingViewer) {
    $.zoomingViewer.open(tileSources);
  } else {
    $.zoomingViewer = OpenSeadragon({
      id:            "zoom-content",
      prefixUrl:     "",
      springStiffness:        10,
      showReferenceStrip:     (tileSources.length > 1),
      autoHideControls:       true,
      controlsFadeDelay: 100,
      controlsFadeLength: 500,
      referenceStripSizeRatio: 0.15,
      showNavigator:  true,
      tileSources: tileSources,
      initialPage: DCV.zoomingViewerInitialPage,
      zoomInButton:   "zoom-in-control",
      zoomOutButton:  "zoom-out-control",
      homeButton:     "zoom-home-control",
      fullPageButton: "zoom-full-control",
      nextButton:     "zoom-next-control",
      previousButton: "zoom-prev-control",
      showSequenceControl:  (tileSources.length > 1)
    });
    $.zoomingViewer.addHandler('open',handleImageChange,null);
    $.zoomingViewer.addHandler('full-screen', function() {
      $('#zoom-full-control > i').toggleClass('glyphicon-resize-small');
      $('#toggle-metadata-control').toggleClass('hidden');
    });
  }
}

function setTilesFromQuery(dataUrl){
  $.ajax({
    dataType: "json",
    url: dataUrl,
    success: function(data){
      var sources = [];
      var children = data['children'] || [data];
      var children_map = {};

      for (var i=0; i<children.length; i++) {
        var child = children[i];
        children_map[child['id']] = child;
      }
      $("#children-links a[rel='child']").each(function() {
        var child = null;
        var dataId = $(this).attr('data-id');
        for (var i=0; i< children.length; i++) {
          if (children[i]['id'] == dataId) {
            child = children[i];
            break;
          }
          if (children[i]['contentids'].indexOf(dataId) > -1) {
            child = children[i];
            break;
          }
        }
        if (child && child['rft_id']) {
          $(this).attr('data-rftId',child['rft_id'])
          //sources[sources.length] = new OpenSeadragon.DjTileSource($.djUrl, child['rft_id']);
          sources[sources.length] = new OpenSeadragon.CalculatedDjTileSource($.djUrl, child['rft_id'], child['width'], child['length']);
        }
      });
      $.tileSources = sources;
      initZoomingViewer($.tileSources);
    }
  });
}

function handleImageChange(event) {
  var src = event.source;
  var tile = event.tileSource;
  var bsUrl = null;
  var dataId = "[none]";
  $("#children-links a[rel='child']").each(function(){
    if ($(this).attr('data-rftId') == src.imageID) {
      bsUrl = $(this).attr('data-bytestreams');
      loadByteStreams(bsUrl, setDownloads);
    }
  })
}

function loadByteStreams(bsUrl, handler) {
  if (!$.bytestreams) $.bytestreams = {};
  if ($.bytestreams[bsUrl]) {
    if (handler) handler.call(this,$.bytestreams[bsUrl]);
  } else {
    $.ajax({
      dataType: "json",
      url: bsUrl,
      success: function(data){
        $.bytestreams[bsUrl] = data;
        if (handler) handler.call(this,data);
      }
    });
  }
}

function setDownloads(data) {
  $('#dlwrapper ul.dropdown-menu').each(function(list){
    $(this).html(getListItemContentFromBytestreamsData(data));
  });
}
function favoriteChild(child) {
  var screenUrl = $(child).attr('href');
  var screenImg = $('#favorite-child img').first();
  var dataCounter = $(child).attr('data-counter');
  var dataSequence = $(child).attr('data-sequence');
  var bytestreamsUrl = $(child).attr('data-bytestreams');
  var ccap = $(child).next('.caption').find('h5').text();
  if (screenUrl != screenImg.attr('src')) {
    $('#ct').html('<span style="color:#555;">Loading...</span>');
    $('#child_gallery a.document').removeClass('selected');
    $(child).addClass('selected');
    screenImg[0].onload = function(){
      screenImg.attr('data-counter', dataCounter);
      screenImg.attr('data-sequence', dataSequence);
      screenImg.attr('data-bytestreams', bytestreamsUrl);
      $('#ct').html(ccap);
    };
    screenImg.attr('src', screenUrl);
  }
  loadDownloadsForItemShowPage();
}
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
      $('#content .col-sm-3').removeClass('col-sm-12').removeClass('list-view');
      $('#content .col-sm-3').find('h3').addClass('ellipsis');
      $('#content .col-sm-3 .tombstone').removeClass('row');
      //$('#content .col-sm-3').find('[data-lv="lv"]').contents().unwrap();
      $('#content .col-sm-3 .thumbnail').removeClass('col-sm-2');
      $('#content .index-show-list-fields').addClass('hidden');
      $('#content .index-show-tombstone-fields').removeClass('hidden');
      $('#grid-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'grid', 1);
  } else if (searchMode == 'list') {
      $('#content .col-sm-3').addClass('col-sm-12').addClass('list-view');
      $('#content .col-sm-3').find('h3').removeClass('ellipsis');
      //$('#content .col-sm-3 .tombstone').addClass('row').wrapInner('<div data-lv="lv" class="col-sm-12" />');
      $('#content .col-sm-3 .thumbnail').addClass('col-sm-2');
      $('#content .index-show-tombstone-fields').addClass('hidden');
      $('#content .index-show-list-fields').removeClass('hidden');
      $('#list-mode').addClass('btn-success');
      createCookie(DCV.SearchResults.CookieNames.searchMode, 'list', 1);
  } else {
    alert('Invalid search mode: ' + searchMode);
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
    current:"{current} of {total}",
    title: function(){
      var otit = $(this).data('original-title');
      return otit;
    },
    onComplete: function(){
      var bsUrl = $(this).attr('data-bytestreams');
      loadByteStreams(bsUrl);
    },
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
