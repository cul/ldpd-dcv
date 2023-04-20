module Dcv::Search::Map
  class ShowScriptComponent < ViewComponent::Base
    def initialize(action: nil)
      @action = action
    end
    def search_params
      default_params ={ lat: '_lat_', long: '_long_', search_field: params[:search_field] || 'all_text_teim', q: params[:q] || '' }
      default_params[:action] = @action if @action
      default_params.reverse_merge(params.permit!.to_h.except(:utf8))
    end

    def uri_component
      CGI.escape(controller.search_action_url(search_params)).html_safe
    end

    def call
      src = <<-SRC
<script>
  DCV.mapCoordinateSearchUrl = decodeURIComponent('#{uri_component}');
</script>
SRC
      src.html_safe
    end
  end
end