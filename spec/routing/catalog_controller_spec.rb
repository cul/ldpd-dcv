require 'rails_helper'

describe CatalogController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/").to route_to(controller: "catalog", action:"home")
    end
    it "routes pid ids to show action" do
      expect(:get => "/catalog/cul:12345").to route_to(controller: "catalog", action:"show", id: "cul:12345")
    end
    it "routes doi ids to show action" do
      expect(:get => "/catalog/10.123/1a2b-3c4d5e").to route_to(controller: "catalog", action:"show", id: "10.123/1a2b-3c4d5e")
    end
  end
end
