$(document).ready(function(){
  if($('#synchronizer-widget').length > 0) {
    var widgetOptions = {
        player: {
          type: 'video',
      		url: $('#synchronizer-widget').attr('data-media-url')
        },
        transcript: {
          id: 'input-transcript',
          url: $('#synchronizer-widget').attr('data-captions-url')
        },
        index: {
          id: 'input-index',
          url: $('#synchronizer-widget').attr('data-index-document-url')
        },
        options: {
          previewOnly: true
        }
      };

      var synchronizerWidget = new OHSynchronizer(widgetOptions);
      OHSynchronizer.playerControls.bindNavControls(); //bind modal forward/back/etc. nav controls. TODO: Move this to widget js instead of DLC js
      OHSynchronizer.errorHandler = function(e) {
        alert(e);
      }
  };
});
