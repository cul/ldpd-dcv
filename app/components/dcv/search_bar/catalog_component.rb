# frozen_string_literal: true

module Dcv::SearchBar
  class CatalogComponent < Dcv::SearchBar::DefaultComponent
    def search_fields_component_class
      Dcv::SearchBar::SearchFields::HiddenComponent
    end
  end
end
