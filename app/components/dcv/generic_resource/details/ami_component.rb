# frozen_string_literal: true

module Dcv::GenericResource::Details
  class AmiComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior

    delegate :bytestream_content_path, :get_resolved_asset_url, :render_media_element_streaming_player, to: :helpers

    def initialize(document:, local_downloads: false, logo_path: nil, poster_url: nil, **_opts)
      super
      @document = document
      @local_downloads = local_downloads
      @logo_path = logo_path
      @poster_url = poster_url
    end

    def poster_url
      @poster_url ||= get_resolved_asset_url(id: @document.id, pid: @document.id, size: 768, type: 'full', format: 'jpg')
    end

    def wowza_media_token_url
      @wowza_media_token_url ||= helpers.wowza_media_token_url(@document)
    end

    def media_url
      wowza_media_token_url || helpers.bytestream_content_path(catalog_id: @document.id, bytestream_id: 'access')
    end

    def player_options
      options = { captions_path:  captions_path }
      unless wowza_media_token_url
        options[:media_type] = 'audio/mp4' if is_audio?
        options[:media_type] = 'video/mp4' if is_video?
      end
      options[:logo_path] = @logo_path
      options
    end

    def has_captions?
      has_datastream?('captions')
    end

    def is_audio?
      (@document.fetch('dc_type_ssm',[]) & ['Sound', 'Audio']).present?
    end

    def is_video?
      (@document.fetch('dc_type_ssm',[]) & ['MovingImage', 'Video']).present?
    end

    def captions_path
      bytestream_content_path(catalog_id: @document.id, bytestream_id: 'captions') if has_captions?
    end

    def call
      render_media_element_streaming_player(media_url, poster_url, **player_options)
    end
  end
end
