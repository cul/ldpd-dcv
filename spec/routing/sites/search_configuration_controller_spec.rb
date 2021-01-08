require 'rails_helper'

describe Sites::SearchConfigurationController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/foo/search_configuration").to route_to(controller: "sites/search_configuration", action:"show", site_slug:"foo")
      expect(:get => "/restricted/foo/search_configuration").to route_to(controller: "restricted/sites/search_configuration", action:"show", site_slug:"foo")
    end
    it "routes to #edit" do
      expect(:get => "/foo/search_configuration/edit").to route_to(controller: "sites/search_configuration", action:"edit", site_slug:"foo")
      expect(:get => "/restricted/foo/search_configuration/edit").to route_to(controller: "restricted/sites/search_configuration", action:"edit", site_slug:"foo")
    end
    it "routes to #update" do
      expect(:patch => "/foo/search_configuration").to route_to(controller: "sites/search_configuration", action:"update", site_slug:"foo")
      expect(:patch => "/restricted/foo/search_configuration").to route_to(controller: "restricted/sites/search_configuration", action:"update", site_slug:"foo")
    end
  end
  describe "url_helpers" do
    it 'produces expected public sites paths' do
      expect(site_search_configuration_path(site_slug: 'foo')).to eql("/foo/search_configuration")
      expect(edit_site_search_configuration_path(site_slug: 'foo')).to eql("/foo/search_configuration/edit")
    end
    it 'produces expected restricted sites paths' do
      expect(restricted_site_search_configuration_path(site_slug: 'foo')).to eql("/restricted/foo/search_configuration")
      expect(edit_restricted_site_search_configuration_path(site_slug: 'foo')).to eql("/restricted/foo/search_configuration/edit")
    end
  end
end
