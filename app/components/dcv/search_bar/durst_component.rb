# frozen_string_literal: true

module Dcv::SearchBar
  class DurstComponent < Dcv::SearchBar::DefaultComponent
    delegate :durst_format_list, :query_has_constraints?, to: :helpers
  end
end
