# frozen_string_literal: true

module Dcv::Search
  class OpenSearchMetadataComponent < ViewComponent::Base
    def initialize(response:)
      @response = response
    end
    def call
      helpers.safe_join [
        tag(:meta, name: "totalResults", content: @response.total),
        tag(:meta, name: "startIndex", content: @response.start),
        tag(:meta, name: "itemsPerPage", content: @response.limit_value)
      ]
    end
  end
end