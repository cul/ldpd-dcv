import OpenSeadragon from "../application/openseadragon-cul-multicdn-override.js.erb";
//initialPage is an optional parameter
export function initTiles(initialPage) {
  const zoomingViewerInitialPage = (typeof(initialPage) != 'undefined') ? initialPage : 0;

  if ($('#zoom-gallery').length > 0) {
    var tileSources = [];
    $('#children-links a[rel="child"]').each(function(){
      tileSources.push($(this).attr('data-zoom-info-url'));
    });

    initZoomingViewer(tileSources, zoomingViewerInitialPage);
  }
}

function initZoomingViewer(tileSources, zoomingViewerInitialPage = 0) {
  OpenSeadragon.setString("Tooltips.Home","Reset zoom");
  $.zoomingViewer = OpenSeadragon({
    id:            "zoom-content",
    prefixUrl:     "",
    springStiffness: 10,
    sequenceMode: (tileSources.length > 1),
    showReferenceStrip: (tileSources.length > 1),
    autoHideControls: true,
    controlsFadeDelay: 100,
    controlsFadeLength: 500,
    referenceStripSizeRatio: 0.15,
    maxZoomPixelRatio: 3,
    showNavigator:  true,
    tileSources: tileSources,
    initialPage: zoomingViewerInitialPage,
    zoomInButton:   "zoom-in-control",
    zoomOutButton:  "zoom-out-control",
    homeButton:     "zoom-home-control",
    fullPageButton: "zoom-full-control",
    nextButton:     "zoom-next-control",
    previousButton: "zoom-prev-control",
    showSequenceControl:  (tileSources.length > 1)
  });
  $.zoomingViewer.addHandler('open',handleImageChange,null);
  $.zoomingViewer.addHandler('full-screen', function(e) {
    $('#zoom-full-control > i').toggleClass('fa-compress', e.fullScreen);
    $('#toggle-metadata-control').toggleClass('hidden');
  });
  if (tileSources.length < 2) {
    $('#zoom-prev-control, #zoom-next-control').hide();
  }
}

function handleImageChange(event) {
  var src = event.source;
  var dataId = "[none]";
  $("#children-links a[rel='child']").each(function(){
    var iiifInfoUrl = $(this).attr('data-zoom-info-url');
    if (iiifInfoUrl == event.source) {
      var dataInfoUrl = $(this).attr('data-info-url');
      $('#download-button').attr('data-iiif-info-url', dataInfoUrl);
    }
  });
}
