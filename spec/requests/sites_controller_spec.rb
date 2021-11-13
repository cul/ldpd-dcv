require 'rails_helper'

describe SitesController, type: :request do
  include_context "site fixtures for features"
  describe "index" do
    before do
      get "/sites.json"
    end
    let(:response_json) { JSON.load(response.body) }
    let(:external_urls) { response_json.map { |site| site['external_url'] } }
    it "links to internal_site" do
      expect(external_urls).to include("http://www.example.com/internal_site")
    end
    it "links to external_site" do
      expect(external_urls).to include("https://external.library.columbia.edu")
    end
    it "doesn't link to catalog, sites" do
      expect(external_urls).not_to include("http://example.com/catalog")
      expect(external_urls).not_to include("http://example.com/sites")
    end
  end
end
