module Dcv::MediaElementHelper
  # render a video streaming player with a non-token protected src
  def render_media_element_streaming_video_player(wowza_project, video_path, poster_path, captions_path: nil, width:1024, height:576, logo_path: nil, **args)
    wowza_url = Dcv::Utils::WowzaUtils.wowza_url_for_video_location(video_path, nil)
    wowza_url.nil? ? nil : render_media_element_streaming_player(url, poster_path, captions_path: captions_path, width: width, height: height)
  end

  def render_media_element_streaming_audio_player(url, poster_path, captions_path: nil, width: 1024, height: 576, media_type: "application/x-mpegURL", logo_path: nil, **args)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    if poster_path.nil?
      poster_path = asset_path('dcv/audio-poster.png')
    end
    logo_attr = "player-logo=\"#{logo_path}\"" if logo_path
    return %(
      <div class="media-container">
        <audio poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%" #{logo_attr}>
          <source src="#{url}" type="#{media_type}" />
          #{track_element}
        </audio>
      </div>
    ).html_safe
  end

  def render_media_element_streaming_player(url, poster_path, captions_path:nil, width:1024, height:576, media_type:"application/x-mpegURL", logo_path: nil, **args)
    if captions_path
      # important not to mark up as default, or browser and player will both display
      track_element = '<track label="English" kind="subtitles" srclang="en" src="' + captions_path + '" />'
    end
    logo_attr = "player-logo=\"#{logo_path}\"" if logo_path
    return %(
      <div class="media-container">
        <video poster="#{poster_path}" preload="none" width="#{width}" height="#{height}" style="width:100%" #{logo_attr}>
          <source src="#{url}" type="#{media_type}" />
          #{track_element}
        </video>
      </div>
    ).html_safe
  end

  def inline_svg(path)
    return unless path =~ /\.svg$/
    File.read(File.join(Rails.root, 'app', 'assets', 'images', path)).html_safe
  end
end
