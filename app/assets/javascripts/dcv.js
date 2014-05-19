$(function() {
  $('body').on('click', '#list-mode', function() {
      $('#content .col-sm-3').addClass('col-sm-12').addClass('list-view');
      $('#content .col-sm-3 .thumbnail').addClass('col-sm-2');
      $('#content .col-sm-3 .index_title').addClass('col-sm-9');
      $('#grid-mode').removeClass('btn-success').addClass('btn-default');
      $('#content .index-show-fields').removeClass('hidden');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#grid-mode', function() {
      $('#content .col-sm-3').removeClass('col-sm-12').removeClass('list-view');
      $('#content .col-sm-3 .thumbnail').removeClass('col-sm-2');
      $('#content .col-sm-3 .index_title').removeClass('col-sm-9');
      $('#list-mode').removeClass('btn-success').addClass('btn-default');
      $('#content .index-show-fields').addClass('hidden');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#unzoom-mode', function(){
     // hide the zooming stuff
      $('div#zoom-gallery').addClass('hidden');

      $('ul#child_items').removeClass('hidden');
      $('#zoom-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#zoom-mode', function(){
     // do some stuff with a data url
     if (!$.tileSources){
       $.djUrl = "http://iris.cul.columbia.edu:8888/view/";
       $.ajax({
        dataType: "json",
        url: this.getAttribute('data-url'),
        success: function(data){
          var sources = [];
          var children = data['children'] || [];
          var children_map = {};

          for (var i=0; i<children.length; i++) {
            var child = children[i];
            children_map[child['id']] = child;
          }
          $("a[rel='document-link']").each(function() {
            var child = null;
            var dataId = $(this).attr('data-id');
            for (var i=0; i< children.length; i++) {
              if (children[i]['contentids'].indexOf(dataId) > -1) {
                child = children[i];
                break;
              }
            }
            if (child && child['rft_id']) {
            //sources[sources.length] = new OpenSeadragon.DjTileSource($.djUrl, child['rft_id']);
            sources[sources.length] = new OpenSeadragon.CalculatedDjTileSource($.djUrl, child['rft_id'], child['width'], child['length']);
            }
          });
          $.tileSources = sources;
          OpenSeadragon({
            id:            "zoom-content",
            prefixUrl:     "/assets/seadragon/",
            toolbar:       "zoom-toolbar",
            springStiffness:        10,
            showReferenceStrip:     true,
            autoHideControls:       false,
            showNavigator:  true,
            tileSources: $.tileSources
          });
        }
      });
    }
    // hide the non-zooming stuff
    $('ul#child_items').addClass('hidden');
    // OSD the zooming div
    $('div#zoom-gallery').removeClass('hidden');
    $('#unzoom-mode').removeClass('btn-success').addClass('btn-default');
    $(this).addClass('btn-success');
  });
});

//** CULTNBW START **/
  CULh_colorfg = '#000000'; // topnavbar foreground color. hex value. ex: #002B7F
  CULh_colorbg = '#444444'; // topnavbar background color. hex value. ex: #779BC3
  CULh_nobs = 1; // uncomment to NOT load our bootstrap javascript file and or use your own (v2.3.x required)
//** /CULTNBW END **/
