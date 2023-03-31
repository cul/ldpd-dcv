# frozen_string_literal: true

module Dcv
  class ProjectCardComponent < ViewComponent::Base
    DEFAULT_CLASSES = ['bg-transparent']
    def initialize(project_data:, counter: nil, additional_classes: [])
      @project_data = project_data
      @counter = counter
      @card_classes = DEFAULT_CLASSES + additional_classes
    end
    def card_classes
      @card_classes
    end
    def dcv_search_link
      @dcv_search_link ||= @project_data[:browse_url]
    end
    def external_url
      @external_url ||= @project_data[:external_url]
    end
    def digital_project_id_base
      @digital_project_id_base ||= @project_data[:id].sub(':', '')
    end
    def browse_label
      "Browse #{html_escape_once(@project_data[:name])} content".html_safe
    end
    def proj_counter
      @counter
    end
    def project_image
      image_tag(@project_data[:image], class: 'card-img-top img-responsive', itemprop: 'image', aria: { hidden: "true" }, alt: "")
    end
  end
end