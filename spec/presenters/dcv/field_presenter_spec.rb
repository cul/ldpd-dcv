require 'rails_helper'

describe Dcv::FieldPresenter do
  include_context "a solr document"

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:search_action_path) { '/search' }
  let(:search_state) { Dcv::SearchState.new({}, blacklight_config) }
  let(:view_context) { double(ActionController::Base, blacklight_config: blacklight_config, search_state: search_state, search_action_path: search_action_path) }
  let(:presenter) { described_class.new(view_context, solr_document, blacklight_config.show_fields['dc_type_ssm']) }

  before do
    blacklight_config.add_show_field 'dc_type_ssm', label: 'DcType', link_to_facet: true
  end

  it "does not link the values without a configured facet" do
    expect(presenter.render).to eql "Unknown"
  end

  context "facet field is configured" do
    before do
      blacklight_config.add_facet_field 'dc_type_ssm', label: 'DcType'
      allow(view_context).to receive(:link_to).and_return ('success')
    end

    it "links the values" do
      expect(presenter.render).to eql "success"
    end
  end
end