# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer
  class MovingImageComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :bytestream_content_path, :get_resolved_asset_url, :render_media_element_streaming_player, to: :helpers

    def initialize(document:, child:, child_index:, local_downloads: false, poster_url: nil, **_opts)
      super
      @document = document
      @child = child
      @child_index = child_index
      @poster_url = poster_url
      @local_downloads = local_downloads
    end

    def child_title
      @child[:title].present? ? @child[:title].strip : ''
    end

    def poster_url
      @poster_url ||= get_resolved_asset_url(id: @child[:id], pid: @child[:pid], size: 768, type: 'full', format: 'jpg')
    end

    def wowza_media_token_url
      @wowza_media_token_url ||= helpers.wowza_media_token_url(@child)
    end

    def media_url
      wowza_media_token_url || helpers.bytestream_content_path(catalog_id: @child[:pid], bytestream_id: 'access')
    end

    def player_options
      options = { captions_path:  captions_path }
      options[:media_type] = 'video/mp4' unless wowza_media_token_url
      options
    end

    def has_captions?
      has_datastream?('captions')
    end

    def captions_path
      bytestream_content_path(catalog_id: @child[:id], bytestream_id: 'captions') if has_captions?
    end
  end
end
