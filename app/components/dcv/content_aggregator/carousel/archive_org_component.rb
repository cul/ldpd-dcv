# frozen_string_literal: true

module Dcv::ContentAggregator::Carousel
  class ArchiveOrgComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :current_user, :get_archive_org_details_url, :get_archive_org_download_url, :iframe_url_for_document, to: :helpers

    renders_one :gallery, Dcv::ContentAggregator::Gallery::ArchiveOrgComponent

    def initialize(document:, local_downloads:, structured_children: nil, parent_title: nil, **_opts)
      super
      @document = document
      @local_downloads = local_downloads
      @structured_children = structured_children
      @parent_title = parent_title
    end

    def before_render
      with_gallery(document: @document)
    end

    def parent_title
      @document['title_ssm'].first.strip
    end

    def child_viewer_component_for(document:, child:, child_index:)
      dc_type_string = child[:dc_type].present? ? child[:dc_type].underscore.gsub(/\s+/, '_') : ''
      case dc_type_string
      when 'moving_image'
        Dcv::ContentAggregator::ChildViewer::MovingImageComponent.new(document: @document, child: child, child_index: child_index)
      when 'sound'
        Dcv::ContentAggregator::ChildViewer::SoundComponent.new(document: @document, child: child, child_index: child_index)
      when 'software'
        Dcv::ContentAggregator::ChildViewer::SoftwareComponent.new(document: @document, child: child, child_index: child_index)
      else
        Dcv::ContentAggregator::ChildViewer::ArchiveOrgComponent.new(document: @document, child: child, child_index: child_index)
      end
    end
  end
end
