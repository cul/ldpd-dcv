//= require 'ableplayer/js.cookie.2.2.0'
//= require 'ableplayer/hls'
//= require 'ableplayer/ableplayer.3.0'
import Hls from 'hls.js';
require('../src/ableplayer/ableplayer.3.0');

$(document).ready(function(){
  $('.able-player video, .able-player audio, video.able-player, audio.able-player').each(function(){
     var media = $(this)[0];
     var mediaUrl = $('source', this)[0].src;
     if (new URL(mediaUrl).pathname.match(/.m3u8$/i)) {
       var hls = new Hls();
       hls.loadSource(mediaUrl);
       hls.attachMedia(media);
     }
  });
});
