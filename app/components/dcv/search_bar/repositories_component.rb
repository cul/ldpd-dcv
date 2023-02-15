# frozen_string_literal: true

module Dcv::SearchBar
  class RepositoriesComponent < Dcv::SearchBar::DefaultComponent
    delegate :default_document_index_view_type, to: :helpers

    def initialize(content_availability: nil, **_opts)
      super(**_opts)
      @content_availability = content_availability
    end

    def start_over_params
      if @params.dig(:f, :content_availability).present?
        super.to_h.merge("f[content_availability][]" => @params.dig(:f, :content_availability))
      else
        super
      end
    end
  end
end
