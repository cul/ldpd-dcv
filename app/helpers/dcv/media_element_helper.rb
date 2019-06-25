module Dcv::MediaElementHelper
  def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, width=1024, height=576)
    return ('<div class="mejs-ted"><div class="mediaelement-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
        <source type="application/dash+xml" src="https://firehose.cul.columbia.edu:8443/' + wowza_project + '/_definst_/mp4:' + video_path + '/manifest.mpd" />
        <source type="application/x-mpegURL" src="https://firehose.cul.columbia.edu:8443/' + wowza_project + '/_definst_/mp4:' + video_path + '/playlist.m3u8" />
        <source type="video/rtmp" src="rtmps://firehose.cul.columbia.edu:8443/' + wowza_project + '/_definst_/mp4:' + video_path + '" />
      </video>
    </div></div>').html_safe
  end

  def render_media_element_streaming_audio_player(url, poster_path, width=1024, height=576)
    # TODO: Change this to audio element instead of video
    return ('<div class="mejs-ted"><div class="mediaelement-player">
      <audio width="' + width.to_s + '" style="width:100%;" controls="controls" preload="none">
        <source type="application/x-mpegURL" src="' + url + '" />
      </audio>
    </div></div>').html_safe
  end

  def render_media_element_streaming_player(url, poster_path, width=1024, height=576)
    return ('<div class="mejs-ted"><div class="mediaelement-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
        <source type="application/x-mpegURL" src="' + url + '" />
      </video>
    </div></div>').html_safe
  end

  def render_media_element_progressive_download_video_player(video_url, poster_path, width=1024, height=576)
    return ('<div class="mejs-ted"><div class="mediaelement-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" controls="controls" preload="none">
          <source type="video/mp4" src="' + video_url + '" />
      </video>
    </div></div>').html_safe
  end

  def render_media_element_progressive_download_audio_player(audio_url)
    return (
      '<audio class="mediaelement-player" style="width:100%;" controls="controls" preload="none">
          <source type="audio/mp3" src="' + audio_url + '" />
      </audio>'
    ).html_safe
  end

end
