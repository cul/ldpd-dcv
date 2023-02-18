# frozen_string_literal: true

module Dcv
  class SearchContextComponent < Blacklight::SearchContextComponent
    def initialize(document:, **opts)
      super(**opts)
      @document = document
    end
    def render?
      @document['dc_type_ssm']&.first != 'FileSystem'
    end
  end
end
