# frozen_string_literal: true

module Dcv
  class PageImageComponent < ViewComponent::Base
    def initialize(depictable:, blacklight_config:, allow_inset: true)
      @depictable = depictable
      @image = depictable.site_page_images.first
      @search_service = Dcv::SearchService.new(config: blacklight_config, user_params: {})
      @allow_inset = allow_inset
    end

    def image_item
      if @image&.image_identifier =~ /^doi:/
        @solr_document ||= begin
          query_opts = { q: "{!raw f=ezid_doi_ssim v=$id}", fq: ["object_state_ssi:A"] }
          solr_response, solr_document = @search_service.fetch(@image.image_identifier, query_opts)
          solr_document || SolrDocument.new
        end
      end
    end

    def render?
      image_url
    end

    def reference_url
      @solr_document&.persistent_url
    end

    def reference_link_id
      "#{@depictable.class.name.downcase}-#{@depictable.id}-#{@image&.id}-link"
    end

    def figure_opts
      opts = {
        class: ["figure"]
      }
      if @allow_inset && @image&.style == "inset"
        opts[:class] <<  "figure-inset"
      else
        opts[:class] << "figure-hero"
      end
      if reference_url
        opts[:role] = "button"
        opts[:onclick] = "document.getElementById('hero-link').click();"
        opts[:tabindex] = "0"
      end
      opts
    end

    def image_caption
      @image&.caption.present? ? @image.caption : image_item&.title
    end

    def image_opts
      opts = {
        alt: image_caption, class:"figure-img img-fluid rounded mx-auto"
      }

    end

    def image_url
      return nil unless @image&.image_identifier
      case @image.image_identifier.split(':')[0]
      when 'doi'
        item_image_url
      when 'asset'
        asset_image_url
      when 'lweb'
        lweb_image_url
      else
        nil
      end
    end

    def item_image_url
      image_id = image_item&.schema_image_identifier || image_item&.id
      return unless image_id
      Dcv::Utils::CdnUtils.asset_url(id: image_id, size: 768, type: 'full', format: 'jpg')
    end

    def asset_image_url
      @image.image_identifier.sub(/^asset:/,"")
    end

    def lweb_image_url
      @image.image_identifier.sub(/^lweb:/,"https://library.columbia.edu")
    end
  end
end