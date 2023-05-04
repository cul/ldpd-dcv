require 'rails_helper'

describe Resolve::DoisController, :type => :routing do
  let(:legacy_id) { 'rbml_css_0055' }
  describe "routing" do
    it "routes to #resolve" do
      expect(:get => "/resolve/catalog/#{legacy_id}").to route_to(controller: "resolve/catalog", action:"show", id: legacy_id)
    end
  end
  describe "url_helpers" do
    it 'produces resolver paths' do
      expect(resolve_catalog_path(id: legacy_id)).to eql("/resolve/catalog/#{legacy_id}")
    end
  end
end
