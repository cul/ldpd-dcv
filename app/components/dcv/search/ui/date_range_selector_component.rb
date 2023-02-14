# frozen_string_literal: true

module Dcv::Search::Ui
  class DateRangeSelectorComponent < ViewComponent::Base
    delegate :active_site_palette, to: :helpers

    def initialize(date_year_segment_data:, **_opts)
      super
      @date_year_segment_data = date_year_segment_data
    end

    def render?
      controller.subsite_config.dig('date_search_configuration', 'show_timeline')
    end
  end
end