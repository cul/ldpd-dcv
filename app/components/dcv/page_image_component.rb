# frozen_string_literal: true

module Dcv
  class PageImageComponent < ViewComponent::Base
    def initialize(page:, blacklight_config:)
      @page = page
      @image = page.site_page_images.first
      @search_service = Dcv::SearchService.new(config: blacklight_config, user_params: {})
    end

    def image_item
      if @image
        @solr_document ||= begin
          query_opts = { q: "{!raw f=ezid_doi_ssim v=$id}", fq: ["object_state_ssi:A"] }
          solr_response, solr_document = @search_service.fetch("doi:#{@image.doi}", query_opts)
          solr_document
        end
      end
    end

    def render?
      image_item
    end

    def reference_url
      @solr_document&.persistent_url
    end

    def image_caption
      @solr_document&.title
    end

    def image_url
      image_id = @solr_document&.schema_image_identifier || @solr_document&.id
      return unless image_id
      Dcv::Utils::CdnUtils.asset_url(id: image_id, size: 768, type: 'full', format: 'jpg')
    end
  end
end