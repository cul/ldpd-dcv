# frozen_string_literal: true

module Dcv
  class ConstraintsComponent < Blacklight::ConstraintsComponent
    def initialize(**args)
      super
      @start_over_component = nil
      @query_constraint_component_options = { classes: "query btn-group-sm" }
      @facet_constraint_component_options = { classes: "btn-group-sm" }
    end

    def before_render
      with_additional_constraint do
        render date_range_constraint if render_date_range?
      end
      with_additional_constraint do
        render coordinates_constraint if render_coordinates?
      end
      with_additional_constraint do
        render durst_constraint if render_durst?
      end
    end

    def render_date_range?
      params[:start_year] && params[:end_year]
    end

    def date_range_constraint
      # In ISO 8601, 1 B.C.E == '0000' and 2 B.C.E. == '0001'
      start_year_label = (params[:start_year].to_i <= 0) ? ((params[:start_year].to_i-1)*-1).to_s + ' BCE' : params[:start_year] + ' CE'
      end_year_label = (params[:end_year].to_i <= 0) ? ((params[:end_year].to_i-1)*-1).to_s + ' BCE' : params[:end_year] + ' CE'

      if params[:start_year].present? && params[:end_year].present?
        value_ = start_year_label + ' - ' + end_year_label
      elsif params[:start_year].present?
        value_ = start_year_label + ' - Present'
      elsif params[:end_year].present?
        value_ = end_year_label + ' or Earlier'
      end
      remove_path_ = url_for(helpers.search_state.params_for_search.except(:start_year, :end_year))
      Blacklight::ConstraintLayoutComponent.new(label: 'Date Range', value: value_, remove_path: remove_path_, classes: "btn-group-sm")
    end

    def render_coordinates?
      params[:lat] && params[:long]
    end

    def coordinates_constraint
      value_ = params[:lat] + ',' + params[:long]
      remove_path_ = url_for(helpers.search_state.params_for_search.except(:lat, :long))
      Blacklight::ConstraintLayoutComponent.new(label: 'Coordinates', value: value_, remove_path: remove_path_, classes: "btn-group-sm")
    end

    def render_durst?
      params[:durst_favorites]
    end

    def durst_constraint
      remove_path_ = url_for(helpers.search_state.params_for_search.except(:durst_favorites))
      Blacklight::ConstraintLayoutComponent.new(label: 'Show', value: "Seymour's Favorites", remove_path: remove_path_, classes: "btn-group-sm")
    end
  end
end