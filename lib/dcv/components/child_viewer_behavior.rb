module Dcv::Components
  module ChildViewerBehavior
    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end
  end
end