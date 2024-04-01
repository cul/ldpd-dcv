require 'rails_helper'

describe SitesController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/sites").to route_to(controller: "sites", action:"index")
      expect(:get => "/restricted/sites").to route_to(controller: "restricted/sites", action:"index")
    end
    it "routes to #home" do
      expect(:get => "/foo").to route_to(controller: "sites", action:"home", slug:"foo")
      expect(:get => "/restricted/foo").to route_to(controller: "restricted/sites", action:"home", slug:"foo")
    end
    it "routes to #edit" do
      expect(:get => "/foo/edit").to route_to(controller: "sites", action:"edit", slug:"foo")
      expect(:get => "/restricted/foo/edit").to route_to(controller: "restricted/sites", action:"edit", slug:"foo")
    end
    it "routes to #update" do
      expect(:patch => "/foo").to route_to(controller: "sites", action:"update", slug:"foo")
      expect(:patch => "/restricted/foo").to route_to(controller: "restricted/sites", action:"update", slug:"foo")
    end
    it "routes to pages" do
      expect(:get => "/foo/oof").to route_to(controller: "sites/pages", action:"show", site_slug: 'foo', slug:"oof")
      expect(:get => "/restricted/foo/oof").to route_to(controller: "restricted/sites/pages", action:"show", site_slug: 'foo', slug:"oof")
    end
  end
  describe "url_helpers" do
    it do
      expect(restricted_site_path('foo')).to eql("/restricted/foo")
      expect(site_path('foo')).to eql("/foo")
    end
  end
  describe "url_for" do
    let(:routing_params) do
      { action: "home", controller: "/sites", slug: "ohac", repository_id: "NNC-RB", only_path: true }
    end
    let(:expexted_path) { '/ohac?repository_id=NNC-RB' }
    it do
      expect(url_for(routing_params)).to eql(expexted_path)
    end
  end
end
