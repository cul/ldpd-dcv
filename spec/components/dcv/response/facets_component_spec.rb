# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Response::FacetsComponent, type: :component do
  subject(:component) do
    described_class.new(
      blacklight_config: blacklight_config, hide_heading: hide_heading, response: solr_response
    )
  end

  let(:blacklight_config)  do
    _blacklight_config = Blacklight::Configuration.new
    _blacklight_config.add_facet_field applied_facet_key, label: 'Applied'
    _blacklight_config.add_facet_field hidden_facet_key, label: 'Hidden', show: false
    _blacklight_config
  end
  let(:applied_facet_key) { 'facet_field_applied' }
  let(:applied_facet_config) { blacklight_config.facet_fields[applied_facet_key] }
  let(:hidden_facet_key) { 'facet_field_hidden' }
  let(:hidden_facet_config) { blacklight_config.facet_fields[hidden_facet_key] }

  let(:solr_response)  do
    double(Blacklight::Solr::Response)
  end
  let(:applied_facet) do
    double(name: applied_facet_key, sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Value', hits: 1234)])
  end
  let(:hidden_facet) do
    double(name: hidden_facet_key, sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Surprise', hits: 123)])
  end

  let(:hide_heading) { true }

  let(:view_context) { controller.view_context }

  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  before do
    allow(solr_response).to receive(:aggregations).and_return(
      { applied_facet_key => applied_facet, hidden_facet_key => hidden_facet }
    )

    allow(view_context).to receive(:facet_field_names).with(nil).and_return([applied_facet_key])
    allow(view_context).to receive(:facet_limit_for).with(applied_facet_key).and_return(5)
    allow(view_context).to receive(:should_render_field?).with(applied_facet_config, applied_facet).and_return(true)
    allow(view_context).to receive(:blacklight_config).and_return(blacklight_config)

    allow(controller).to receive(:view_context).and_return(view_context)
    allow(controller).to receive(:subsite_config).and_return({})
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "renders hidden facets as query terms" do
    expect(Blacklight::FacetComponent).to receive(:new).with(
      display_facet: applied_facet,
      field_config: blacklight_config.facet_fields[applied_facet_key],
      response: solr_response,
      component: Dcv::FacetFieldListComponent,
      layout: nil
    ).and_call_original
    expect(rendered).to have_selector '#facet-panel-collapse'
  end
end