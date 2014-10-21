$(function() {

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

  //If we're on an item show page, load download links
  if($('#item-show-downloads').length > 0) {
    loadDownloadsForItemShowPage($('#favorite-child img').attr('data-info-url'));
  }

});


function loadDownloadsForItemShowPage(infoUrl) {
  $('#item-show-downloads li.downloadItem').remove();
  $('#item-show-downloads li.downloadItem').append('<li class="placeholder"><a href="#">Loading downloads...</a></li>');

  $.ajax({
    dataType: "json",
    url: infoUrl,
    success: function(data){
      $('#item-show-downloads li.placeholder').remove();
      $('#item-show-downloads').append(getListItemContentFromInfoRequestData(data));
    }
  });
}


function getListItemContentFromInfoRequestData(data) {
  var li_html = '';

  if (data['available']) {
    scaledImages = data['scaled']['sizes'];
    for(var i=0;i<scaledImages.length;i++){
      dlName = 'PNG (' + scaledImages[i]['width'] + ' x ' + scaledImages[i]['height'] + ')';
      li_html += '<li class="downloadItem"><a href="' + scaledImages[i]["url"] + '?download=true' + '" target="_blank"><span class="glyphicon glyphicon-download"></span> ' + dlName + '</a></li>'
    }
  } else {
    li_html += '<li class="downloadItem"><a href="#">Downloads currently unavailable.  Please check back later.</a></li>'
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

  if ($('#zoom-gallery').length > 0) {
    var tileSources = [];
    $('#children-links a[rel="child"]').each(function(){
      tileSources.push($(this).attr('data-zoom-info-url'));
    });
    initZoomingViewer(tileSources);
  }

}
function initZoomingViewer(tileSources) {
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

function setTilesFromQuery(dataUrl){
  $.ajax({
    dataType: "json",
    url: dataUrl,
    success: function(data){
      var sources = [];
      var children = data['children'] || [data];
      var children_map = {};

      var foundZoomingImage = true;

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

          //$.djUrl = "http://dvorak.cul.columbia.edu:8888/view/";  //Uncomment if we use Dvorak djatoka

          //sources[sources.length] = new OpenSeadragon.CalculatedDjTileSource($.djUrl, child['rft_id'], child['width'], child['length']); //Uncomment when we use iris djatoka
          //sources[sources.length] = new OpenSeadragon.CalculatedDjTileSource($.djUrl, child['id'], child['width'], child['length']); //Uncomment when we use Dvorak djatoka
          //sources[sources.length] = $.djUrl + 'images/' + child['id'] + '.dzi'; //Uncomment if we use repository cache for DZI
          sources[sources.length] = $.djUrl + child['id'] + '/info.json';
        } else {
          foundZoomingImage = false;
        }
      });

      if (foundZoomingImage) {
        $.tileSources = sources;
        initZoomingViewer($.tileSources);
      } else {
        $('#zoom-gallery').html('The zoomable version of this image is not yet available.');
      }
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
      dataInfoUrl = $(this).attr('data-info-url');
      loadByteStreams(bsUrl);
      loadDownloadsForItemShowPage(dataInfoUrl);
    }
  });
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

function favoriteChild(child) {
  var screenUrl = $(child).attr('href');
  var screenImg = $('#favorite-child img').first();
  var dataCounter = $(child).attr('data-counter');
  var dataSequence = $(child).attr('data-sequence');
  var bytestreamsUrl = $(child).attr('data-bytestreams');
  var infoUrl = $(child).attr('data-info-url');
  var ccap = $(child).next('.caption').find('h5').text();
  if (screenUrl != screenImg.attr('src')) {
    $('#ct').html('<span style="color:#555;">Loading...</span>');
    $('#child_gallery a.document').removeClass('selected');
    $(child).addClass('selected');
    screenImg[0].onload = function(){
      screenImg.attr('data-counter', dataCounter);
      screenImg.attr('data-sequence', dataSequence);
      screenImg.attr('data-bytestreams', bytestreamsUrl);
      screenImg.attr('data-info-url', infoUrl);
      $('#ct').html(ccap);
      loadDownloadsForItemShowPage(infoUrl);
    };
    screenImg.attr('src', screenUrl);
  }
}
