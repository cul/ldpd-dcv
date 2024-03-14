# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Response::ViewTypeComponent, type: :component do
  subject(:component) do
    described_class.new(
      response: solr_response, views: {}, search_state: search_state, selected: nil, subsite_config: subsite_config
    )
  end

  let(:blacklight_config)  do
    Blacklight::Configuration.new
  end
  let(:query_params) { { q: 'testParamValue' } }
  let(:search_state) { Blacklight::SearchState.new(query_params.with_indifferent_access, blacklight_config) }
  let(:solr_response)  do
    double(Blacklight::Solr::Response, params: query_params)
  end

  let(:show_other_sources) { false }
  let(:show_timeline) { false }
  let(:site) do
    FactoryBot.create(:site, search_configuration: {
      date_search_configuration: {
        show_timeline: show_timeline
      },
      display_options: {
        show_other_sources: show_other_sources
      }
    })
  end
  let(:subsite_config) do
    site.to_subsite_config
  end

  let(:view_context) { controller.view_context }

  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  before do
    allow(view_context).to receive(:blacklight_config).and_return(blacklight_config)
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(controller).to receive(:subsite_config).and_return(subsite_config)
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "renders the grid/list controls" do
    expect(rendered).to have_selector '#grid-mode'
    expect(rendered).to have_selector '#list-mode'
  end

  context "date histogram enabled" do
    let(:show_timeline) { true }

    it "renders the date histogram button" do
      expect(rendered).to have_selector '#grid-mode'
      expect(rendered).to have_selector '#list-mode'
      expect(rendered).to have_selector '#date-graph-toggle'
    end
  end

  context "other sources enabled" do
    let(:show_other_sources) { true }

    it "renders the other sources widget" do
      expect(rendered).to have_selector '#grid-mode'
      expect(rendered).to have_selector '#list-mode'
      expect(rendered).to have_selector '#extended-search-mode'
    end    
  end
end