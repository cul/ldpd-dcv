$(function() {
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
      $('.search-result-display').hide();
      $('#search-results-standard').show();
      $('.result-type-button').removeClass('btn-success').addClass('btn-default');
      $('.results-pagination').show();

      $('#content .col-sm-3').addClass('col-sm-12').addClass('list-view');
      $('#content .col-sm-3 .thumbnail').addClass('col-sm-2');
      $('#content .index-show-tombstone-fields').addClass('hidden');
      $('#content .index-show-list-fields').removeClass('hidden');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#grid-mode', function() {
      $('.search-result-display').hide();
      $('#search-results-standard').show();
      $('.result-type-button').removeClass('btn-success').addClass('btn-default');
      $('.results-pagination').show();

      $('#content .col-sm-3').removeClass('col-sm-12').removeClass('list-view');
      $('#content .col-sm-3 .thumbnail').removeClass('col-sm-2');
      $('#content .index-show-list-fields').addClass('hidden');
      $('#content .index-show-tombstone-fields').removeClass('hidden');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#date-graph-mode', function() {
    $('.search-result-display').hide();
    $('#search-results-date-graph').show();
    $('.result-type-button').removeClass('btn-success').addClass('btn-default');
    $('.results-pagination').hide();

    DCV.DateRangeGraphSelector.resizeCanvas();
    $(this).addClass('btn-success');
  });
  //Hide search-results-date-graph by default
  $('#search-results-date-graph').hide();

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

  //Date Range Graph Setup
  DCV.DateRangeGraphSelector.init();
  DCV.DateRangeSlider.init();

  $('.child-scroll').niceScroll({cursorminheight: "46", cursorcolor:"#111", cursorborder:"1px solid #ccc", autohidemode: false, cursorborderradius: "2px", cursorwidth: "8"});

});

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
      autoHideControls:       false,
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
    if (handler) handler.call(this,data);
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
    li_html = '';
    for(var i=0;i<data.length;i++){
      dlName = data[i]["title"] + '.' + data[i]["url"].match(/\.([^.]+)$/)[1];
      dlName += ' (' + data[i]["width"] + 'x' + data[i]["length"] + ')';
      li_html += '<li><a href="' + data[i]["url"] + '" target="_blank">' + dlName + '</a></li>'
    }
    $(this).html(li_html);
  });
}
function favoriteChild(child) {
  var screenUrl = $(child).attr('href');
  var screenImg = $('#favorite-child img').first();
  var dataCounter = $(child).attr('data-counter');
  var dataSequence = $(child).attr('data-sequence');
  var ccap = $(child).next('.caption').find('h5').text();
  if (screenUrl != screenImg.attr('src')) {
    screenImg.attr('src', screenUrl);
    screenImg.attr('data-counter', dataCounter);
    screenImg.attr('data-sequence', dataSequence);
    $('#ct').html(ccap); // should redo above and fire this after ajax success
  }
}
//** CULTNBW START **/
  CULh_colorfg = '#000000'; // topnavbar foreground color. hex value. ex: #002B7F
  CULh_colorbg = '#444444'; // topnavbar background color. hex value. ex: #779BC3
  CULh_nobs = 1; // uncomment to NOT load our bootstrap javascript file and or use your own (v2.3.x required)
//** /CULTNBW END **/


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
  $('#colorbox').tinyDraggable({handle:'#cboxTitle', exclude:'input, textarea, a, button, i'});

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
