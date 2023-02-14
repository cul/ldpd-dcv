# frozen_string_literal: true

module Dcv::Search::Ui
  class CsvExportComponent < ViewComponent::Base
    delegate :blacklight_config, :search_action_path, to: :helpers

    def render?
      blacklight_config.index.respond_to.has_key?(:csv)
    end
  end
end