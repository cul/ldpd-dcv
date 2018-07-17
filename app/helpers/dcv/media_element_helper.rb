module Dcv::MediaElementHelper

  def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, width=1024, height=576)
    return ('
      <div class="mejs-ted"><div class="mediaelement-player">
        <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
            <source type="application/x-mpegURL" src="https://ldpd-wowza-test1.svc.cul.columbia.edu:8443/vod/mp4:CARN27_v_1_READY_TO_EXPORT.mp4/playlist.m3u8" />
            <source type="video/rtmp" src="rtmps://ldpd-wowza-test1.svc.cul.columbia.edu:8443/vod/_definst_/mp4:sample.mp4" />
        </video>
      </div></div>
    ').html_safe
  end

  def render_media_element_streaming_audio_player(wowza_project, video_path, poster_path, width=1024, height=576)
    # TODO: Change this to audio element instead of video
    return ('
      <div class="mejs-ted"><div class="mediaelement-player">
        <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">

          ################
           <source type="video/rtmp" src="rtmps://ldpd-wowza-test1.svc.columbia.edu:8443/' + wowza_project + '/mp3:' + video_path + '" />
           ################

            <source type="application/x-mpegURL" src="https://ldpd-wowza-test1.svc.cul.columbia.edu:8443/vod/mp4:CARN27_v_1_READY_TO_EXPORT.mp4/playlist.m3u8" />
            <source type="video/rtmp" src="rtmps://ldpd-wowza-test1.svc.cul.columbia.edu:8443/vod/_definst_/mp4:sample.mp4" />
        </video>
      </div></div>
    ').html_safe
  end

  def render_media_element_progressive_download_video_player(video_url, poster_path, width=1024, height=576)
    return ('
      <div class="mejs-ted"><div class="mediaelement-player">
        <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
            <source type="video/mp4" src="' + video_url + '" />
        </video>
      </div></div>
    ').html_safe
  end

  def render_media_element_progressive_download_audio_player(audio_url)

    return (
      '<audio class="mediaelement-player" style="width:100%;" controls="controls" preload="none">
          <source type="audio/mp3" src="' + audio_url + '" />
      </audio>'
    ).html_safe

    # return ('<video class="mediaelement-player" width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
    #       <source type="audio/mp3" src="' + audio_url + '" />
    #
    #       <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
    #       <object width="' + width.to_s + '" height="' + height.to_s + '" type="application/x-shockwave-flash" data="/mediaelement/flashmediaelement.swf">
    #           <param name="movie" value="/mediaelement/flashmediaelement.swf" />
    #           <param name="flashvars" value="controls=true&amp;file=' + audio_url + '" />
    #           <param name="allowFullScreen" value="true" />
    #       </object>
    #   </video>').html_safe

  end

  # def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, width=1024, height=576)
  #   return ('<div class="mejs-ted"><div class="mediaelement-player">
  #     <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
  #         <source type="video/rtmp" src="rtmps://ldpd-wowza-test1.svc.columbia.edu:8443/' + wowza_project + '/mp4:' + video_path + '" />
  #
  #         <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
  #         <object width="' + width.to_s + '" height="' + height.to_s + '" type="application/x-shockwave-flash" data="/mediaelement/flashmediaelement.swf">
  #             <param name="movie" value="/mediaelement/flashmediaelement.swf" />
  #             <param name="flashvars" value="controls=true&amp;file=rtmps://ldpd-wowza-test1.svc.columbia.edu:8443/' + wowza_project + '/mp4:' + video_path + '" />
  #             <param name="allowFullScreen" value="true" />
  #         </object>
  #     </video>
  #   </div></div>').html_safe
  # end
  #
  # def render_media_element_streaming_audio_player(wowza_project, video_path, poster_path, width=1024, height=576)
  #   # TODO: Change this to audio element instead of video
  #   return ('<div class="mejs-ted"><div class="mediaelement-player">
  #     <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
  #         <source type="video/rtmp" src="rtmps://ldpd-wowza-test1.svc.columbia.edu:8443/' + wowza_project + '/mp3:' + video_path + '" />
  #
  #         <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
  #         <object width="' + width.to_s + '" height="' + height.to_s + '" type="application/x-shockwave-flash" data="/mediaelement/flashmediaelement.swf">
  #             <param name="movie" value="/mediaelement/flashmediaelement.swf" />
  #             <param name="flashvars" value="controls=true&amp;file=rtmps://ldpd-wowza-test1.svc.columbia.edu:8443/' + wowza_project + '/mp4:' + video_path + '" />
  #             <param name="allowFullScreen" value="true" />
  #         </object>
  #     </video>
  #   </div></div>').html_safe
  # end
  #
  # def render_media_element_progressive_download_video_player(video_url, poster_path, width=1024, height=576)
  #   return ('<div class="mejs-ted"><div class="mediaelement-player">
  #     <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
  #         <source type="video/mp4" src="' + video_url + '" />
  #
  #         <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
  #         <object width="' + width.to_s + '" height="' + height.to_s + '" type="application/x-shockwave-flash" data="/mediaelement/flashmediaelement.swf">
  #             <param name="movie" value="/mediaelement/flashmediaelement.swf" />
  #             <param name="flashvars" value="controls=true&amp;file=' + video_url + '" />
  #             <param name="allowFullScreen" value="true" />
  #         </object>
  #     </video>
  #   </div></div>').html_safe
  # end
  #
  # def render_media_element_progressive_download_audio_player(audio_url)
  #
  #   return (
  #     '<audio class="mediaelement-player" style="width:100%;" controls="controls" preload="none">
  #         <source type="audio/mp3" src="' + audio_url + '" />
  #     </audio>'
  #   ).html_safe
  #
  #   # return ('<video class="mediaelement-player" width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
  #   #       <source type="audio/mp3" src="' + audio_url + '" />
  #   #
  #   #       <!-- Flash fallback for non-HTML5 browsers without JavaScript -->
  #   #       <object width="' + width.to_s + '" height="' + height.to_s + '" type="application/x-shockwave-flash" data="/mediaelement/flashmediaelement.swf">
  #   #           <param name="movie" value="/mediaelement/flashmediaelement.swf" />
  #   #           <param name="flashvars" value="controls=true&amp;file=' + audio_url + '" />
  #   #           <param name="allowFullScreen" value="true" />
  #   #       </object>
  #   #   </video>').html_safe
  #
  # end

end
