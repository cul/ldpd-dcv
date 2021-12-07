require('../src/ableplayer/ableplayer.4.4.1');

AblePlayer.prototype.getRootPath = function() {
  return "/ableplayer/";
}

const loadHls = function () {
  var mediaUrl = this.media.find('source')[0].src;
  if (new URL(mediaUrl).pathname.match(/.m3u8$/i)) {
    var hls = new Hls({
      backBufferLength: Infinity,
      liveBackBufferLength: 90,
//      debug: true,
    });
    hls.retried = false;
    hls.swapped = false;
    const player = this;
    const media = this.media[0];
    hls.on(Hls.Events.MANIFEST_PARSED, function () {
      hls.attachMedia(media);
    });
    hls.on(Hls.Events.ERROR, function (event, data) {
      if (!data.fatal) return;
      if (!data.err.type === Hls.ErrorTypes.MEDIA_ERROR) return;
      console.log({event, data, media: this.media.error});
      switch(data.details) {
        case Hls.ErrorDetails.BUFFER_INCOMPATIBLE_CODECS_ERROR:
          if (!hls.swapped) {
            hls.swapped = true;
            hls.swapAudioCodec();
            hls.recoverMediaError();
          }
          return;
        case Hls.ErrorDetails.BUFFER_APPEND_ERROR:
        case Hls.ErrorDetails.BUFFER_APPENDING_ERROR:
        case Hls.ErrorDetails.BUFFER_STALLED_ERROR:
          if (!hls.retried) {
            hls.retried = true;
            hls.recoverMediaError();
          } else {
            console.log("already retried");
          }
          return;
        default:
          console.log(Hls.ErrorDetails);
          hls.destroy();
      }
    });
    hls.loadSource(mediaUrl);
  }
};

const toWrap = AblePlayer.prototype.setup;
AblePlayer.prototype.setup = function() {
  loadHls.apply(this);
  toWrap.apply(this);
}

window.AblePlayer = AblePlayer;

$(document).ready(function(){
  $('.able-player video, .able-player audio, video.able-player, audio.able-player').each(function(index, element){
    var mediaRefs = $(this);
    var media = $(this)[0];
    var mediaUrl = $('source', this)[0].src;
    var player = new AblePlayer($(this), $(element));
    var thisObj = $(this);
    AblePlayerInstances.push(player);
  })
});
