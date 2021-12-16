module Dcv::MediaElementHelper
  def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return ('<div class="media-container"><div class="able-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" class="able-player" preload="none">
        <source src="https://firehose.cul.columbia.edu:8443/' + wowza_project + '/_definst_/mp4:' + video_path + '/playlist.m3u8" />
        ' + track_element.to_s + '
      </video>
    </div></div>').html_safe
  end

  def render_media_element_streaming_audio_player(url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return ('<div class="media-container"><div class="able-player">
      <audio width="' + width.to_s + '" style="width:100%;" preload="none">
        <source src="' + url + '" />' + track_element.to_s + '
      </audio>
    </div></div>').html_safe
  end

  def render_media_element_streaming_player(url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return ('<div class="media-container"><div class="able-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" preload="none">
        <source src="' + url + '" />' + track_element.to_s + '
      </video>
    </div></div>').html_safe
  end

  def render_media_element_progressive_download_video_player(video_url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return ('<div class="media-container"><div class="able-player">
      <video width="' + width.to_s + '" height="' + height.to_s + '" style="width:100%;height:100%;" poster="' + poster_path + '" preload="none">
          <source type="video/mp4" src="' + video_url + '" />' + track_element.to_s + '
      </video>
    </div></div>').html_safe
  end

  def render_media_element_progressive_download_audio_player(audio_url, captions_path = nil)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return (
      '<audio style="width:100%;" class="able-player" preload="none">
          <source type="audio/mp3" src="' + audio_url + '" />' + track_element.to_s + '
      </audio>'
    ).html_safe
  end

  def inline_svg(path)
    return unless path =~ /\.svg$/
    File.read(File.join(Rails.root, 'app', 'assets', 'images', path)).html_safe
  end
end
