require 'rails_helper'

describe SitesController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/restricted/sites").to route_to(controller: "restricted/sites", action:"index")
      expect(:get => "/sites").to route_to(controller: "sites", action:"index")
    end
    it "routes to #home" do
      expect(:get => "/restricted/foo").to route_to(controller: "restricted/sites", action:"home", slug:"foo")
      expect(:get => "/foo").to route_to(controller: "sites", action:"home", slug:"foo")
    end
  end
  describe "url_helpers" do
    it do
      expect(restricted_site_path('foo')).to eql("/restricted/foo")
      expect(site_path('foo')).to eql("/foo")
    end
  end
end
