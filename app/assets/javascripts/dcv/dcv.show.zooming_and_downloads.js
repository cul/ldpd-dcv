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

  //If we're on an page that should show downloads, load download links
  if($('#downloads-list').length > 0) {
    loadDownloadsForItemShowPage($('#favorite-child img').attr('data-info-url'));
  }

});

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
    sequenceMode: true,
    showReferenceStrip:     (tileSources.length > 1),
    autoHideControls:       true,
    controlsFadeDelay: 100,
    controlsFadeLength: 500,
    referenceStripSizeRatio: 0.15,
    maxZoomPixelRatio: 3,
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
  if (tileSources.length < 2) {
    $('#zoom-prev-control, #zoom-next-control').hide();
  }
}

function handleImageChange(event) {
  var src = event.source;
  var tile = event.tileSource;
  var dataId = "[none]";
  $("#children-links a[rel='child']").each(function(){
    var iiifInfoUrl = $(this).attr('data-zoom-info-url').replace('/info.json', '');
    if (iiifInfoUrl == src['@id']) {
      dataInfoUrl = $(this).attr('data-info-url');
      loadDownloadsForItemShowPage(dataInfoUrl);
    }
  });
}

function favoriteChild(child) {
  var screenUrl = $(child).attr('href');
  var screenImg = $('#favorite-child img').first();
  var dataCounter = $(child).attr('data-counter');
  var dataSequence = $(child).attr('data-sequence');
  var bytestreamsUrl = $(child).attr('data-bytestreams');
  var infoUrl = $(child).attr('data-info-url');
  var itemInContextUrl = $(child).is('[data-item-in-context-url]') ?  $(child).attr('data-item-in-context-url') : null;
  
  var $childContainer = $(child).closest('.child-container');
  var ccap = $childContainer.find('.caption').find('.index_title').text();
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
      if(itemInContextUrl == null) {
        $('#favorite-child-item-in-context-url').hide();
      } else {
        $('#favorite-child-item-in-context-url').attr('href', itemInContextUrl);
        $('#favorite-child-item-in-context-url').show();
      }
    };
    screenImg.attr('src', screenUrl);
  }
}

function loadDownloadsForItemShowPage(infoUrl) {
  if (!infoUrl) return;
  $('#downloads-list li.downloadItem').remove();
  $('#downloads-list li.downloadItem').append('<li class="placeholder"><a href="#">Loading downloads...</a></li>');
  $.ajax({
    dataType: "json",
    url: infoUrl,
    success: function(data){
      $('#downloads-list li.placeholder').remove();
      $('#downloads-list').append(getListItemContentFromInfoRequestData(data));
    }
  });
}


function getListItemContentFromInfoRequestData(data) {
  var li_html = '';

  var sizes = data['sizes'];
  var sizeNames = ['small', 'medium', 'large', 'x-Large', 'xx-Large', 'xxx-Large']; // Probably more possible sizes than we will offer
  var iiifUrlTemplate = data['@id'] + '/full/_width_,_height_/0/native.jpg?download=true';
  for(var i = 0;i < sizes.length; i++){
    dlName = sizeNames[i] + ' (' + sizes[i]['width'] + ' x ' + sizes[i]['height'] + ')';
    li_html += '<li class="downloadItem"><a href="' + iiifUrlTemplate.replace('_width_', sizes[i]['width']).replace('_height_', sizes[i]['height']) + '" target="_blank"><span class="glyphicon glyphicon-download"></span> ' + dlName + '</a></li>'
  }

  return li_html;
}
