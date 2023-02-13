# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer::ArchiveOrg
  class ButtonPanelComponent < Dcv::ContentAggregator::ChildViewer::ButtonPanelComponent
    delegate :get_archive_org_details_url, :get_archive_org_download_url, :iframe_url_for_document, to: :helpers
    def initialize(child:, document:, **_opts)
      super
    end

    def item_in_context_url
      @item_in_context_url ||= get_archive_org_details_url(@child)
    end

    def zoom_url
      iframe_url_for_document(@child)
    end

    def has_chapters?
      false
    end

    def has_synch?
      false
    end

    def has_iiif?
      @child[:dc_type] == 'StillImage'
    end

    def iiif_info_url
      "https://iiif.archivelab.org/iiif/#{@child[:id]}/manifest.json" if has_iiif?
    end

    def has_download?
      download_content_url || iiif_info_url
    end

    def download_content_url
      get_archive_org_download_url(@child)
    end
  end
end
