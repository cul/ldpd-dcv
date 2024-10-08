# frozen_string_literal: true

module Dcv
  class DocumentComponent < Blacklight::DocumentComponent
    delegate :byte_size_to_text_string, :render_document_class, :render_snippet_with_post_processing, to: :helpers
    delegate :load_subsite, to: :controller
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

      @metadata_component = metadata_component || Blacklight::DocumentMetadataComponent

      @thumbnail_component = thumbnail_component || Blacklight::Document::ThumbnailComponent

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
      with_thumbnail(linked_thumbnail)
      unless partials?
        @view_partials&.each do |view_partial|
          with_partial(view_partial) do
            helpers.render_document_partial @document, view_partial, component: self, document_counter: @document_counter
          end
        end
      end
    end

    def thumbnail_img_tag
      @presenter.thumbnail.thumbnail_tag({ class: 'img-square card-img-top w-100', itemprop: 'thumbnailUrl', alt: short_title }, { suppress_link: true })
    end

    def document_link_params
      helpers.document_link_params(@document, counter: (@do_not_link_to_search ? nil : @counter), class: 'thumbnail')
    end

    def linked_thumbnail
      helpers.link_to(thumbnail_img_tag, helpers.search_state.url_for_document(@document), document_link_params)
    end

    def document_link
      helpers.link_to_document(@document,
                               title: @document['title_ssm'].present? ? @document['title_ssm'][0] : '[Title unavailable]',
                               counter: (@do_not_link_to_search ? nil : @counter))
    end

    # truncate title to 30 characters if present
    def short_title
      title = @presenter.heading
      title = title.first if title.is_a? Array
      if title && title.length > 30
        title = title[0..26] + '...'
      end
      title
    end

    # Iterate over each field that is displayable in the site context for grid mode search results
    # These will be yields in the order of configuration for grid mode, and then within the Blacklight
    # index field definitions
    def each_grid_field(document = @document)
      return unless document
      # the True key here supports custom sites with dedicated Blacklight configurators
      grid_field_types = [true] + load_subsite.search_configuration.display_options.grid_field_types
      grid_fields = grid_field_types.map {|x| [x, []]}.to_h
      helpers.blacklight_config.index_fields.select do |field, field_config|
        grid_key = (grid_field_types & Array(field_config[:grid_display])).first
        grid_fields[grid_key] << [field, field_config] if grid_key && document[field].present?
      end
      grid_field_types.each do |type|
        grid_fields[type].each { |gf| yield gf[0], gf[1] }
      end
    end

    def render_grid_field_value(document:, field:, **_args)
      content_tag(:div, Array(document[field]).first, class: "ellipsis")
    end
  end
end