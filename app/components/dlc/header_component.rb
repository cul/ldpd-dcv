# frozen_string_literal: true

module Dlc
  class HeaderComponent < Blacklight::HeaderComponent
    def initialize(blacklight_config:, current_site:)
      @blacklight_config = blacklight_config
      @current_site = current_site
    end

    attr_reader :blacklight_config, :current_site
  end
end
