# frozen_string_literal: true

module Dcv::SearchBar
  class DefaultComponent < Blacklight::SearchBarComponent
    delegate :query_has_constraints?, :search_action_params, :search_placeholder_text, to: :helpers

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
        _comp = Dcv::Response::CollapsiblePaginationComponent.new(
          response: helpers.instance_variable_get(:@response), theme: 'dcv_collapsible',
          outer_window: 1, window: 1
        )
        unless _comp.will_render?(controller: controller, helpers: helpers)
          _comp = Dcv::SearchContext::CollapsiblePaginationComponent.new(
            search_context: helpers.instance_variable_get(:@search_context),
            search_session: helpers.instance_variable_get(:@search_session)
          )
        end
        _comp
      end
    end
  end
end
