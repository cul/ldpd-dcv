# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Blacklight::Configuration", api: true do
  before { Blacklight::Configuration.define_field_access :geo_field }
  let(:config) do
    Blacklight::Configuration.new
  end

  let(:facetable_field_name) { 'subject_hierarchical_geographic_neighborhood_ssim' }
  let(:unfacetable_field_name) { 'subject_geographic_sim' }

  it "supports defined field sets" do
    config.add_geo_field facetable_field_name, show: false, link: true
    config.add_geo_field unfacetable_field_name, show: false, link: false

    expect(config.geo_fields.length).to eq 2
    expect(config.geo_fields[facetable_field_name].link).to eq true
  end

  it "has the right names" do
    expect(unfacetable_field_name).to eql ActiveFedora::SolrService.solr_name('subject_geographic', :facetable)
    expect(facetable_field_name).to eql ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_neighborhood', :symbol)
  end
end