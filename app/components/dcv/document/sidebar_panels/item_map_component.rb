# frozen_string_literal: true

module Dcv::Document::SidebarPanels
  class ItemMapComponent < ViewComponent::Base
    def initialize(document:)
      @document = document
      @latlong = document['geo'][0].split(',') if document['geo'].present?
    end

    def before_render
      @map_search_settings = helpers.map_search_settings_for_subsite
      @latlong ||= [@map_search_settings['default_lat'] || 0, @map_search_settings['default_long'] || 0]
    end
  end
end