# frozen_string_literal: true

module Dcv::Search::Ui
  class DateRangeSelectorComponent < ViewComponent::Base
    include Dcv::Catalog::DateRangeSelectorBehavior
    delegate :has_search_parameters?, :search_service, :subsite_config,to: :controller
    delegate :active_site_palette, :search_state, to: :helpers

    def initialize(enabled:, **_opts)
      super
      @enabled = enabled
    end

    def render?
      @enabled &&
      subsite_config.dig('date_search_configuration', 'show_timeline') &&
      has_search_parameters? && ['html', nil].include?(params[:format]) &&
      get_date_year_segment_data_for_query
    end

    def reset_range_filter_params
      params.except(:start_year, :end_year).permit!
    end

    def has_range_filter_params?
      params[:start_year].present? || params[:end_year].present?
    end
  end
end