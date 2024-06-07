# frozen_string_literal: true

module Dcv::SearchBar
  class FormatFilterDropdownComponent < Blacklight::Component
    def initialize(format_filter_list: nil)
      @format_filter_list = format_filter_list
    end

    def render?
      @format_filter_list
    end

    def format_filter_list
      @format_filter_list
    end
  end
end
