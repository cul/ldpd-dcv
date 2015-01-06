module Dcv::MediaElementHelper

  def render_media_element_player(wowza_project, video_path)
    return ('<div class="mediaelement-player">
      <video width="320" height="180" style="width:100%;height:100%;" poster="<%= asset_path(partner_data[:rep_image]) %>" controls="controls" preload="none">
          <source type="video/mpd" src="rtmp://firehose.cul.columbia.edu:1935/' + wowza_project + '/mp4:' + video_path + '/manifest.mpd" />
          <source type="video/rtmp" src="rtmp://firehose.cul.columbia.edu:1935/' + wowza_project + '/mp4:' + video_path + '" />

          <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
          <object width="320" height="180" type="application/x-shockwave-flash" data="' + asset_path('mediaelement_rails/flashmediaelement.swf') + '">
              <param name="movie" value="' + asset_path('mediaelement_rails/flashmediaelement.swf') + '" />
              <param name="flashvars" value="controls=true&amp;file=rtmp://firehose.cul.columbia.edu:1935/' + wowza_project + '/mp4:' + video_path + '" />
          </object>
      </video>
    </div>').html_safe
  end

end
