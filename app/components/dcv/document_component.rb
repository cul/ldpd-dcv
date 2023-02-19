# frozen_string_literal: true

module Dcv
  class DocumentComponent < Blacklight::DocumentComponent
    delegate :byte_size_to_text_string, :render_document_class, :render_document_tombstone_field_value, to: :helpers

    # this is a BL8 forward-compatible override
    # - BL8 will pass DocumentPresenter as :document
    # - BL8 will use ViewComponent collection iteration
    # - local params:
    # -- do_not_link_to_search
    # -- search_view
    def initialize(document:, partials: nil,
                   id: nil, classes: [], component: :article, title_component: nil,
                   metadata_component: nil,
                   embed_component: nil,
                   thumbnail_component: nil,
                   document_counter: nil, counter_offset: 0,
                   show: false,
                   do_not_link_to_search: nil,
                   show_counter: true,
                   search_view: nil)
      @document = document.document
      @presenter = document

      @view_partials = partials
      @component = component
      @title_component = title_component
      @id = id || ('document' if show)
      @classes = classes

      @metadata_component = Blacklight::DocumentMetadataComponent

      @thumbnail_component = Blacklight::Document::ThumbnailComponent

      # ViewComponent 3 will change document_counter to be zero-based, but BL8 will accommodate
      @counter = document_counter + counter_offset if document_counter.present?

      @show = show
      @do_not_link_to_search = do_not_link_to_search
      @show_counter = show_counter
      @search_view = search_view
    end

    def before_render
      super
      # @search_state = helpers.search_state
      # @search_session = helpers.search_session
      @search_view ||= "#{controller.default_search_mode}-view"
      # part of superclass in BL8
      unless partials?
        @view_partials&.each do |view_partial|
          with_partial(view_partial) do
            helpers.render_document_partial @document, view_partial, component: self, document_counter: @document_counter
          end
        end
      end
    end

    def thumbnail_img_tag
      @presenter.thumbnail.thumbnail_tag({ class: 'img-square card-img-top w-100', itemprop: 'thumbnailUrl', alt: helpers.short_title(@document) }, { suppress_link: true })
    end

    def document_link_params
      helpers.document_link_params(@document, counter: (@do_not_link_to_search ? nil : @document_counter), class: 'thumbnail')
    end

    def linked_thumbnail
      helpers.link_to(thumbnail_img_tag, helpers.search_state.url_for_document(@document), document_link_params)
    end

    def document_link
      helpers.link_to_document(@document,
                               title: @document['title_ssm'].present? ? @document['title_ssm'][0] : '[Title unavailable]',
                               counter: (@do_not_link_to_search ? nil : @counter))
    end

    def document_tombstone_fields(document = nil)
      helpers.blacklight_config.index_fields.select do |field, field_config|
        field_config[:tombstone_display] && document[field].present?
      end.to_h
    end
  end
end