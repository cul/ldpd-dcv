# frozen_string_literal: true

module Dcv::SearchBar
  class DefaultComponent < Blacklight::SearchBarComponent
    delegate :query_has_constraints?, :search_action_params, :search_placeholder_text, to: :helpers

    def search_fields_component_class
      Dcv::SearchBar::SearchFields::SelectComponent
    end

    def search_placeholder_text
      (!query_has_constraints? ?  t(:"dlc.search_placeholder.new.#{controller.controller_name}", default: :'dlc.search_placeholder.new.default').html_safe : t(:"dlc.search_placeholder.modified.#{controller.controller_name}", default: :'dlc.search_placeholder.modifed.default').html_safe)
    end

    def params_for_new_search
      @params_for_new_search ||= begin
        _pfns = @params.except(:q, :search_field, :qt, :page, :utf8, :format, :"searchpag-mode")
        _pfns[:f] = _pfns[:f].except(:lib_format_sim) if _pfns.has_key?(:f)
        _pfns
      end
   end

    def start_over_params
      params.slice(:search_field, :utf8).permit!
    end

    def start_over_path
      path = URI(@url).path
      query = []
      start_over_params.to_h.each do |k,v|
        if v.is_a? Array
          query.concat v.map {|vx| "#{k}=#{vx}"}
        else
          query << "#{k}=#{v}"
        end
      end
      URI::HTTP.build(path: path, query: query.join('&')).request_uri
    end

    def pagination_component
      return @pagination_component unless @pagination_component.nil?
      @pagination_component = begin
        _comp = Dcv::Response::CompactPaginationComponent.new(
          response: helpers.instance_variable_get(:@response), theme: 'dcv_compact',
          outer_window: 1, window: 1
        )

        if _comp.will_render?(controller: controller, helpers: helpers)
          @pagination_will_render = true
        else
          _comp = Dcv::SearchContext::PaginationComponent.new(
            search_context: helpers.instance_variable_get(:@search_context),
            search_session: helpers.instance_variable_get(:@search_session)
          )
        end
        _comp
      end
    end

    def pagination_will_render?
      if @pagination_will_render.nil?
        @pagination_will_render = pagination_component.will_render?(controller: controller, helpers: helpers)
      end
      @pagination_will_render
    end

    def search_fields_component
      @search_fields_component ||= search_fields_component_class.new(search_fields: search_fields)
    end

    def format_filter_list
      nil
    end

    def format_filter_component
      @format_filter_component ||= FormatFilterDropdownComponent.new(format_filter_list: format_filter_list)
    end
  end
end
