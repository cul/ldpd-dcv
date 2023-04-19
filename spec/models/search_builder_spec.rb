require 'rails_helper'

describe SearchBuilder do
  let(:user_params) { Hash.new }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  let(:search_builder) { described_class.new scope }

  describe "multiselect_facet_feature" do
    let(:facet_field) { 'facet_field' }
    let(:facet_values) {  ['one', 'two', 'three']}
    let(:facet_tag) { 'lib_format-tag' }
    let(:facet_label) { 'Facet Label' }
    let(:facet_config) { { multiselect: true, ex: facet_tag, label: facet_label } }
    let(:user_params) { { f: { facet_field => facet_values } } }
    subject(:query_parameters) { search_builder.with(user_params).processed_parameters }
    context "when multiselect is configured" do
      before do
        blacklight_config.configure do |config|
          config.add_facet_field facet_field, facet_config
        end
      end
      it "submits a OR joined fq" do
        expect(query_parameters[:fq]).to include "{!tag=#{facet_tag}}#{facet_field}:(\"#{facet_values.join('" OR "')}\")"
      end
    end
    describe 'filter_random_suppressed_content' do
      let(:search_builder) { described_class.new(scope).append(:filter_random_suppressed_content) }
      it 'adds a suppress random filter' do
        expect(query_parameters[:fq]).to include "!suppress_in_random_bsi:true"
      end
    end
  end
end