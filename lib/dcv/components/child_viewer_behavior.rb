module Dcv::Components
  module ChildViewerBehavior
    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end

    def child_viewer_component_for(child: , child_index:)
      dc_type_string = child[:dc_type].present? ? child[:dc_type].underscore.gsub(/\s+/, '_') : ''
      component_class = Dcv::ContentAggregator::ChildViewer::ImageComponent
      if can_access_asset?(child.with_indifferent_access)
        component_class = Dcv::ContentAggregator::ChildViewer::SoundComponent if 'sound' == dc_type_string
        component_class = Dcv::ContentAggregator::ChildViewer::MovingImageComponent if 'moving_image' == dc_type_string
        component_class = Dcv::ContentAggregator::ChildViewer::SoftwareComponent if 'software' == dc_type_string
      end
      component_class.new(document: @document, local_downloads: @local_downloads, child: child, child_index: child_index)
    end
  end
end