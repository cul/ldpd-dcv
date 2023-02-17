# frozen_string_literal: true

module Dcv::Search::Map
  class EmbeddedResultsComponent < ViewComponent::Base
    delegate :extract_map_data_from_document_list, to: :helpers

    def initialize(document_list:, map_search_settings:, map_data_json: nil, force_use_default_center: false, map_show_items: nil)
      @document_list = document_list
      @force_use_default_center = force_use_default_center
      @map_show_items = map_show_items.nil? ? map_search_settings['show_items'] : map_show_items
      @map_data_json = map_data_json&.html_safe
      @map_search_settings = map_search_settings
    end

    def before_render
      @map_data_json ||= extract_map_data_from_document_list(@document_list).to_json.html_safe
      @map_default_center_lat = params[:lat] || @map_search_settings['default_lat'] || 0
      @map_default_center_long = params[:long] || @map_search_settings['default_long'] || 0
      @map_default_zoom_level = @map_search_settings['default_zoom'] || 11
      @map_max_zoom_level = @map_search_settings['max_zoom'] || 13
    end

    def image_thumb_template
      helpers.get_asset_url(id: '_document_id_', size: 256, type: 'featured', format: 'jpg')
    end

    def book_icon_image
      helpers.image_url('book-placeholder.png')
    end
  end
end