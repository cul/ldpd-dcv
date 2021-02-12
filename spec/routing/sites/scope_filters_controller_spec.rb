require 'rails_helper'

describe Sites::ScopeFiltersController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/foo/scope_filters").to route_to(controller: "sites/scope_filters", action:"show", site_slug:"foo")
      expect(:get => "/restricted/foo/scope_filters").to route_to(controller: "restricted/sites/scope_filters", action:"show", site_slug:"foo")
    end
    it "routes to #edit" do
      expect(:get => "/foo/scope_filters/edit").to route_to(controller: "sites/scope_filters", action:"edit", site_slug:"foo")
      expect(:get => "/restricted/foo/scope_filters/edit").to route_to(controller: "restricted/sites/scope_filters", action:"edit", site_slug:"foo")
    end
    it "routes to #update" do
      expect(:patch => "/foo/scope_filters").to route_to(controller: "sites/scope_filters", action:"update", site_slug:"foo")
      expect(:patch => "/restricted/foo/scope_filters").to route_to(controller: "restricted/sites/scope_filters", action:"update", site_slug:"foo")
    end
  end
  describe "url_helpers" do
    it 'produces expected public sites paths' do
      expect(site_scope_filters_path(site_slug: 'foo')).to eql("/foo/scope_filters")
      expect(edit_site_scope_filters_path(site_slug: 'foo')).to eql("/foo/scope_filters/edit")
    end
    it 'produces expected restricted sites paths' do
      expect(restricted_site_scope_filters_path(site_slug: 'foo')).to eql("/restricted/foo/scope_filters")
      expect(edit_restricted_site_scope_filters_path(site_slug: 'foo')).to eql("/restricted/foo/scope_filters/edit")
    end
  end
end
