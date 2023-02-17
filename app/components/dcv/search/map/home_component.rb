module Dcv::Search::Map
  class HomeComponent < ViewComponent::Base
    def call
      content_tag :div, id: "home-map-container" do
        render Dcv::Search::Map::ShowScriptComponent.new(action: "index")
      end
    end
  end
end