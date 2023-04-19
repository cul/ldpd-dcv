# frozen_string_literal: true

module Dcv::Catalog
  class ProjectListComponent < ViewComponent::Base
    def render?
      digital_projects.present?
    end

    def digital_projects
      @digital_projects ||= begin
        fi = controller.digital_projects
      rescue Exception => e
        Rails.logger.warn("Digital projects query on #{controller} raised #{e.message}")
        []
      end
    end
  end
end