# frozen_string_literal: true

module Dcv::ContentAggregator::Gallery
  class ArchiveOrgComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :poster_url, :render_thumbnail_tag, :zoom_url_for_doc, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end
  end
end
