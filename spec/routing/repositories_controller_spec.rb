require 'rails_helper'

describe RepositoriesController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/NNC-RB").to route_to(controller: "repositories", action:"show", id: "NNC-RB")
    end
    it "routes to #reading-room" do
      expect(:get => "/NNC-RB/reading-room").to route_to(controller: "repositories", action:"reading_room", repository_id: "NNC-RB")
    end
    it "routes to /about to site pages" do
      expect(:get => "/NNC-RB/about").to route_to(controller: "sites/pages", action:"show", site_slug: "NNC-RB", slug: "about")
    end
  end
end
