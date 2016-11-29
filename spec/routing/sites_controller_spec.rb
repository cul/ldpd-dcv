require 'rails_helper'

describe SitesController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/restricted/sites").to route_to(controller: "restricted/sites", action:"index")
      expect(:get => "/sites").to route_to(controller: "sites", action:"index")
      expect(:get => "/").to route_to(controller: "sites", action:"index")
    end
    it "routes to #show" do
      expect(:get => "/restricted/sites/foo").to route_to(controller: "restricted/sites", action:"show", slug:"foo")
      expect(:get => "/sites/foo").to route_to(controller: "sites", action:"show", slug:"foo")
    end
  end
  describe "url_helpers" do
    it do
      expect(restricted_site_path('foo')).to eql("/restricted/sites/foo")
      expect(site_path('foo')).to eql("/sites/foo")
    end
  end
end
