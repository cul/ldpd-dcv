# frozen_string_literal: true

module Dcv::SearchBar
  class DefaultComponent < Blacklight::SearchBarComponent
    delegate :query_has_constraints?, :search_action_params, :search_placeholder_text, to: :helpers

    def start_over_params
      params.slice(:search_field, :utf8)
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
  end
end
