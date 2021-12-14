require('../src/ableplayer/ableplayer.4.4.1');

AblePlayer.prototype.getRootPath = function() {
  return "/ableplayer/";
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
