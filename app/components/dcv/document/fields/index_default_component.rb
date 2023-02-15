# frozen_string_literal: true

module Dcv::Document::Fields
  # default partial to display solr document fields in catalog index view
  class IndexDefaultComponent < ViewComponent::Base
    #delegate :render_index_field_label, to: :helpers

    def initialize(presenter:, **_opts)
      super
      @presenter = presenter
    end
  end
end