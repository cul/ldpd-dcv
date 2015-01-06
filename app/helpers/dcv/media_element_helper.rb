module Dcv::MediaElementHelper

  def render_media_element_player(wowza_project, video_path, poster_path)
    return ('<div class="mejs-ted"><div class="mediaelement-player">
      <video width="320" height="180" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
          <source type="video/rtmp" src="rtmp://firehose.cul.columbia.edu:1935/' + wowza_project + '/mp4:' + video_path + '" />

          <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
          <object width="320" height="180" type="application/x-shockwave-flash" data="' + asset_path('mediaelement/flashmediaelement.swf') + '">
              <param name="movie" value="' + asset_path('mediaelement/flashmediaelement.swf') + '" />
              <param name="flashvars" value="controls=true&amp;file=rtmp://firehose.cul.columbia.edu:1935/' + wowza_project + '/mp4:' + video_path + '" />
              <param name="allowFullScreen" value="true" />
          </object>
      </video>
    </div></div>').html_safe
  end

end
