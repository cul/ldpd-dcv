export const synchronizerReady = function(){
  if($('#synchronizer-widget').length > 0) {

    var widgetOptions = {
        player: {
          type: 'video',
      		url: $('#synchronizer-widget').attr('data-media-url')
        },
        options: {
          previewOnly: true
        }
    };
    if ($('#synchronizer-widget').attr('data-chapters-url')) {
      widgetOptions.index = {
        id: 'input-index',
        url: $('#synchronizer-widget').attr('data-chapters-url')
      }
    } else {
      widgetOptions.transcript = {
        id: 'input-transcript',
        url: $('#synchronizer-widget').attr('data-synchronized_transcript-url')
      }
    }

    var synchronizerWidget = new OHSynchronizer(widgetOptions);
    OHSynchronizer.errorHandler = function(e) {
      alert(e);
    }
  };
};
