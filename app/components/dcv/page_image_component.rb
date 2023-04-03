# frozen_string_literal: true

module Dcv
  class PageImageComponent < ViewComponent::Base
    BREAKPOINTS = [[1200, 1140], [992, 960], [768, 720], [576, 540]]
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

    def container_opts
      opts = {class: []}
      if @allow_inset && @image&.style == "inset"
        opts[:class] <<  "figure-inset-container"
      else
        opts[:class] << "container" << "figure-hero-container"
      end
      if reference_url
        opts[:class] << "figure-collections-container"
        # opts[:style] = "background-image: url(\"#{item_image_url}\");"
      end
      opts
    end

    def figure_opts
      opts = {
        class: ["figure figure-dcv"]
      }
      if reference_url
        opts[:role] = "button"
        opts[:tabindex] = "0"
      end
      opts
    end

    def image_caption_value
      @image&.caption.present? ? @image.caption : image_item&.title
    end

    def image_caption
      if reference_url
        link_to(image_caption_value, reference_url, class: ["stretched-link"])
      else
        image_caption_value
      end
    end

    def image_opts
      alt = @image&.alt_text.present? ? @image.alt_text : image_caption_value
      opts = {
        alt: alt, class:"figure-img img-fluid rounded mx-auto"
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

    def item_image_url(size = 768)
      image_id = image_item&.schema_image_identifier || image_item&.id
      return unless image_id
      max_height = (size / 16 * 9).ceil
      Dcv::Utils::CdnUtils.asset_url(id: image_id, width: size, height: max_height, type: 'full', format: 'jpg')
    end

    def picture_tag
      content_tag :picture do
        safe_join(BREAKPOINTS[0...-1].map do |media_min, content_max|
          # <source srcset="mdn-logo-wide.png" media="(min-width: 600px)" />
          tag(:source, srcset: item_image_url(content_max), media: "(min-width:#{media_min}px)")
        end << image_tag(item_image_url(BREAKPOINTS[-1][1]), image_opts))
      end
    end

    def asset_image_url
      @image.image_identifier.sub(/^asset:/,"")
    end

    def lweb_image_url
      @image.image_identifier.sub(/^lweb:/,"https://library.columbia.edu")
    end
  end
end