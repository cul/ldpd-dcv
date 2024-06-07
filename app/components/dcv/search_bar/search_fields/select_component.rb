# frozen_string_literal: true

module Dcv::SearchBar::SearchFields
  class SelectComponent < Blacklight::Component
    def initialize(search_fields: nil)
      @search_fields = search_fields
    end

    def render?
      search_fields
    end

    def search_fields
      @search_fields
    end
  end
end
