# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer::ButtonPanel
  class DefaultComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior

    DEFAULT_ASPECT_RATIO = '9x9'
    attr_reader :child, :parent, :id_base

    delegate :archive_org_id_for_document, :has_viewable_children?, :is_publicly_available_asset?, to: :helpers

    def initialize(child:, document: SolrDocument.new, presenter: nil, **opts)
      super
      @document = document
      @presenter = presenter
      @child = child
      @id_base = child[:id].gsub(/[^A-Za-z0-9]/,'')
      @child_index = opts[:child_index]
      @local_downloads = opts[:local_downloads]
    end

    def before_render
      @presenter ||= helpers.document_presenter(@document)
    end

    def item_in_context_url
      @item_in_context_url ||= Array(@child[:lib_item_in_context_url_ssm]).first || @document.item_in_context_url
    end

    def has_zoom?
      helpers.is_image_document?(@child, :dc_type) || helpers.is_text_document?(@child, :dc_type)
    end

    def show_zoom?
      has_zoom? && (has_viewable_children?(document: @document) || archive_org_id_for_document(@document) || @document.resource_result?)
    end

    def zoom_url
      helpers.zoom_url_for_doc(@document, @child, layout:(request.path.split('/')[1]), title: 'false', initial_page: @child_index) if has_zoom?
    end

    def has_chapters?
      has_datastream?('chapters', @child)
    end

    def has_synch?
      has_datastream?('synchronized_transcript', @child)
    end

    def has_iiif?
      @local_downloads && helpers.is_image_document?(@child, :dc_type)
    end

    def iiif_info_url
      return nil unless has_iiif?

      @iiif_info_url ||= helpers.get_resolved_asset_info_url(id: @child[:id], pid: @child[:pid], image_format: 'jpg')
    end

    def has_download?
      download_content_url || iiif_info_url
    end

    def download_content_url
      return nil unless @local_downloads && !has_iiif?

      @download_content_url ||= bytestreams_url(catalog_id: @child[:pid])
    end

    def show_embed?
      is_publicly_available_asset?(@child) && @child.doi_identifier
    end

    def embed_aspect_ratio
      t("embeds.aspect_ratio.#{@child[:dc_type]}", default: DEFAULT_ASPECT_RATIO)
    end

    def embed_url
      helpers.embed_url(id: @child.doi_identifier, layout: request.path.split('/')[1])
    end
  end
end