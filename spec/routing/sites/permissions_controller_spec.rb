require 'rails_helper'

describe Sites::PermissionsController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/foo/permissions").to route_to(controller: "sites/permissions", action:"show", site_slug:"foo")
      expect(:get => "/restricted/foo/permissions").to route_to(controller: "restricted/sites/permissions", action:"show", site_slug:"foo")
    end
    it "routes to #edit" do
      expect(:get => "/foo/permissions/edit").to route_to(controller: "sites/permissions", action:"edit", site_slug:"foo")
      expect(:get => "/restricted/foo/permissions/edit").to route_to(controller: "restricted/sites/permissions", action:"edit", site_slug:"foo")
    end
    it "routes to #update" do
      expect(:patch => "/foo/permissions").to route_to(controller: "sites/permissions", action:"update", site_slug:"foo")
      expect(:patch => "/restricted/foo/permissions").to route_to(controller: "restricted/sites/permissions", action:"update", site_slug:"foo")
    end
  end
  describe "url_helpers" do
    it 'produces expected public sites paths' do
      expect(site_permissions_path(site_slug: 'foo')).to eql("/foo/permissions")
      expect(edit_site_permissions_path(site_slug: 'foo')).to eql("/foo/permissions/edit")
    end
    it 'produces expected restricted sites paths' do
      expect(restricted_site_permissions_path(site_slug: 'foo')).to eql("/restricted/foo/permissions")
      expect(edit_restricted_site_permissions_path(site_slug: 'foo')).to eql("/restricted/foo/permissions/edit")
    end
  end
end
