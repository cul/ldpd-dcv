# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Dcv::Search::Map::ShowScriptComponent, type: :component do
  let(:component) { described_class.new }

  let(:params_for_search) { { } }
  let(:params) { ActionController::Parameters.new(params_for_search) }

  let(:subsite_config) do
    {
      'map_search_configuration' => {
        'enabled' => true
      }
    }
  end

  include_context "renderable view components"

  before do
    component.instance_variable_set(:@view_context, view_context)
    allow(view_context).to receive(:current_user)
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:subsite_config).and_return(subsite_config)
  end

  describe "uri_component" do
    subject(:search_uri) { component.uri_component }
    let(:expected_url) { '/expected' }
    let(:search_params) {  { 'lat' => '_lat_', 'long' => '_long_', 'q' => '', 'search_field' => 'all_text_teim' } }
    context "custom site controller" do
      let(:controller) { DurstController.new }
      let(:expected_routing_params) { {'controller' => 'durst', 'action' => :index}.merge(search_params) }
      before do
        allow(controller).to receive(:url_for).with(expected_routing_params).and_return(expected_url)
      end
      it "returns a Durst search link" do
        expect(search_uri).to eql(CGI.escape(expected_url))
      end
    end
    context 'site search controller' do
      let(:controller) { Sites::SearchController.new }
      let(:subsite) { FactoryBot.create(:site) }
      let(:expected_routing_params) { [subsite.slug, search_params] }
      before do
        allow(controller).to receive(:load_subsite).and_return(subsite)
        allow(controller).to receive(:site_search_url).with(*expected_routing_params).and_return(expected_url)
      end
      it "returns a site search link" do
        expect(search_uri).to eql(CGI.escape(expected_url))
      end
    end
  end
end
