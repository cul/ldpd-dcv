module Dcv::MediaElementHelper
  def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return %(
      <div class="media-container">
        <video poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%">
          <source src="https://firehose.cul.columbia.edu:8443/#{wowza_project}/_definst_/mp4:#{video_path}/playlist.m3u8" type="application/x-mpegURL" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

  def render_media_element_streaming_audio_player(url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    if poster_path.nil?
      poster_path = asset_pack_path('media/images/dcv/audio-poster.png')
    end
    return %(
      <div class="media-container">
        <audio poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%">
          <source src="#{url}" type="application/x-mpegURL" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

  def render_media_element_streaming_player(url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return %(
      <div class="media-container">
        <video poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%">
          <source src="#{url}" type="application/x-mpegURL" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

  def render_media_element_progressive_download_video_player(video_url, poster_path, captions_path = nil, width=1024, height=576)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    return %(
      <div class="media-container">
        <video poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%">
          <source src="#{url}" type="video/mp4" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

  def render_media_element_progressive_download_audio_player(audio_url, captions_path = nil)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    if poster_path.nil?
      poster_path = asset_pack_path('media/images/dcv/audio-poster.png')
    end
    return %(
      <div class="media-container">
        <audio poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%">
          <source src="#{url}" type="audio/mp4" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

end
