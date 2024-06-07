# frozen_string_literal: true

module Dcv::SearchBar
  class DurstComponent < Dcv::SearchBar::DefaultComponent
    delegate :durst_format_list, :query_has_constraints?, to: :helpers

    def format_filter_list
      @format_filter_list ||= durst_format_list
    end

    def search_placeholder_text
      return 'Modify current search&hellip;'.html_safe if query_has_constraints?
      'Search Postcards, Maps, Photographs, Books, Etc&hellip;'.html_safe
    end
  end
end
