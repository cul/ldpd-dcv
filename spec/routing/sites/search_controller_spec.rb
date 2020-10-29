require 'rails_helper'

describe Sites::SearchController, :type => :routing do
  describe "routing" do
    let(:site_slug) { "foo" }
    let(:doi_prefix) { "10.12345" }
    let(:doi_id) { "1a2b-3c4d5e" }
    let(:doi_id_param) { "#{doi_prefix}/#{doi_id}" }
    let(:internal_id) { 'gee' }
    it "routes to #show" do
      expect(get: "/#{site_slug}/#{doi_prefix}/#{doi_id}").to route_to(controller: "sites/search", action:"show", site_slug: site_slug, id: doi_id_param)
    end
    it "doesn't route extraneous segments into the doi id" do
      expect(get: "/#{site_slug}/#{doi_prefix}/#{doi_id}/x").not_to route_to(controller: "sites/search", action:"show", site_slug: site_slug, id: doi_id_param)
      expect(get: "/#{site_slug}/#{doi_prefix}/#{doi_id}/x").not_to route_to(controller: "sites/search", action:"show", site_slug: site_slug, id: "#{doi_id_param}/x")
    end
    it "routes to #index" do
      expect(get: "/#{site_slug}/search").to route_to(controller: "sites/search", action:"index", site_slug: site_slug)
    end
    it "routes to #preview" do
      expect(get: "/#{site_slug}/previews/#{doi_prefix}/#{doi_id}").to route_to(controller: "sites/search", action:"preview", site_slug: site_slug, id: doi_id_param)
    end
    it "routes to #synchronizer" do
      expect(get: "/#{site_slug}/#{doi_prefix}/#{doi_id}/synchronizer").to route_to(controller: "sites/search", action:"synchronizer", site_slug: site_slug, id: doi_id_param)
    end
    it "routes to #facet" do
      expect(get: "/#{site_slug}/search/facet/#{internal_id}").to route_to(controller: "sites/search", action:"facet", site_slug: site_slug, id: internal_id)
    end
    it "routes to #track" do
      expect(post: "/#{site_slug}/#{doi_prefix}/#{doi_id}/track").not_to route_to(controller: "sites/search", action:"track", site_slug: site_slug, id: doi_id_param)
      expect(post: "/#{site_slug}/#{internal_id}/track").to route_to(controller: "sites/search", action:"track", site_slug: site_slug, id: internal_id)
    end
  end
end
