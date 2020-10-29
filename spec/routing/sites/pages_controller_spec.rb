require 'rails_helper'

describe Sites::PagesController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/foo/gee").to route_to(controller: "sites/pages", action:"show", site_slug:"foo",slug:"gee")
      expect(:get => "/restricted/foo/gee").to route_to(controller: "restricted/sites/pages", action:"show", site_slug:"foo",slug:"gee")
    end
    it "routes to #edit" do
      expect(:get => "/foo/gee/edit").to route_to(controller: "sites/pages", action:"edit", site_slug:"foo",slug:"gee")
      expect(:get => "/restricted/foo/gee/edit").to route_to(controller: "restricted/sites/pages", action:"edit", site_slug:"foo",slug:"gee")
    end
    it "routes to #update" do
      expect(:patch => "/foo/gee").to route_to(controller: "sites/pages", action:"update", site_slug:"foo",slug:"gee")
      expect(:patch => "/restricted/foo/gee").to route_to(controller: "restricted/sites/pages", action:"update", site_slug:"foo",slug:"gee")
    end
    it "routes to #create" do
      expect(post: "/foo/pages").to route_to(controller: "sites/pages", action:"create", site_slug:"foo")
      expect(post: "/restricted/foo/pages").to route_to(controller: "restricted/sites/pages", action:"create", site_slug:"foo")
    end
    it "routes to #destroy" do
      expect(:delete => "/foo/gee").to route_to(controller: "sites/pages", action:"destroy", site_slug:"foo",slug:"gee")
      expect(:delete => "/restricted/foo/gee").to route_to(controller: "restricted/sites/pages", action:"destroy", site_slug:"foo",slug:"gee")
    end
    it "routes to #new" do
      expect(:get => "/foo/pages/new").to route_to(controller: "sites/pages", action:"new", site_slug:"foo")
      expect(:get => "/restricted/foo/pages/new").to route_to(controller: "restricted/sites/pages", action:"new", site_slug:"foo")
    end
    it "empty resource path does not route to #index" do
      expect(:get => "/foo").not_to route_to(controller: "sites/pages", action:"index", site_slug: 'foo')
      expect(:get => "/restricted/foo").not_to route_to(controller: "restricted/sites/pages", action:"index", site_slug: 'foo')
    end
    it "pages resource path does route to #index" do
      expect(:get => "/foo/pages").to route_to(controller: "sites/pages", action:"index", site_slug: 'foo')
      expect(:get => "/restricted/foo/pages").to route_to(controller: "restricted/sites/pages", action:"index", site_slug: 'foo')
    end
    it "does not route asset paths to pages" do
      { 'images' => 'jpg', 'javascripts' => 'js', 'stylesheets' => 'css' }.each do |asset_type, file_ext| 
        expect(get: "/#{asset_type}/foo.#{file_ext}").not_to route_to(controller: "sites/pages", action:"show", site_slug: asset_type, slug: 'foo', format: file_ext)
      end
    end
  end
  describe "url_helpers" do
    it 'produces expected public sites paths' do
      expect(site_page_path('gee', site_slug: 'foo')).to eql("/foo/gee")
      expect(edit_site_page_path('gee', site_slug: 'foo')).to eql("/foo/gee/edit")
      expect(site_pages_path(site_slug: 'foo')).to eql("/foo/pages")
      expect(new_site_page_path(site_slug: 'foo')).to eql("/foo/pages/new")
    end
    it 'produces expected restricted sites paths' do
      expect(restricted_site_page_path('gee', site_slug: 'foo')).to eql("/restricted/foo/gee")
      expect(edit_restricted_site_page_path('gee', site_slug: 'foo')).to eql("/restricted/foo/gee/edit")
      expect(restricted_site_pages_path(site_slug: 'foo')).to eql("/restricted/foo/pages")
      expect(new_restricted_site_page_path(site_slug: 'foo')).to eql("/restricted/foo/pages/new")
    end
  end
end
