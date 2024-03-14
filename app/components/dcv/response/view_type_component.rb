# frozen_string_literal: true

module Dcv::Response
  class ViewTypeComponent < Blacklight::Response::ViewTypeComponent
    # @param [Blacklight::Response] response
    def initialize(response:, views: {}, search_state:, selected: nil, subsite_config:, **_args)
      super(response: response, views: views, search_state: search_state, selected: selected)
      @response = response
      @views = views
      @search_state = search_state
      @selected = selected
      @subsite_config = subsite_config
    end

    def timeline_views?
      @subsite_config.dig('date_search_configuration', 'show_timeline')
    end

    def show_other_sources?
      @subsite_config.dig('display_options', 'show_other_sources')
    end

    def before_render
      return if views.any?

      @views.each do |key, config|
        view(key: key, view: config, selected: @selected == key, search_state: @search_state)
      end
    end

    def render?
      true
    end
  end
end
