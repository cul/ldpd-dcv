require 'rails_helper'

describe Repositories::CatalogController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/NNC-RB/search?q=test").to route_to(controller: "repositories/catalog", action:"index", repository_id: "NNC-RB", q: "test")
    end
    it "routes pid ids to show action" do
      expect(:get => "/NNC-RB/cul:12345").to route_to(controller: "repositories/catalog", action:"show", repository_id: "NNC-RB", id: "cul:12345")
      expect(:get => "/NNC-RB/cul:12345.xml").to route_to(controller: "repositories/catalog", action:"show", repository_id: "NNC-RB", id: "cul:12345", format: 'xml')
    end
    xit "routes doi ids to show action" do
      expect(:get => "/NNC-RB/10.123/1a2b-3c4d5e").to route_to(controller: "repositories/catalog", action:"show", repository_id: "NNC-RB", id: "10.123/1a2b-3c4d5e")
      expect(:get => "/NNC-RB/10.123/1a2b-3c4d5e.xml").to route_to(controller: "repositories/catalog", action:"show", repository_id: "NNC-RB", id: "10.123/1a2b-3c4d5e", format: 'xml')
    end
  end
end
