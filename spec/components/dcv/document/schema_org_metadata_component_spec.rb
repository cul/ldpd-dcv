# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Document::SchemaOrgMetadataComponent, type: :component do
  subject(:component) { described_class.new(document: document) }

  def vc_test_controller_class
    controller
  end

  include_context "renderable view components"

  include_context "a solr document"

  let(:document) { solr_document }



  context "when a field is absent" do
    before do
      solr_data.delete(:abstract_ssm)
    end
    it "does not render the itemprop" do
      expect(rendered).not_to have_selector("meta[itemprop=\"description\"]")
    end
  end

  context 'with a field is present' do
    before do
      solr_data[:abstract_ssm] = ['abstract']
    end
    it "renders the itemprop" do
      expect(rendered).to have_selector("meta[itemprop=\"description\"]", visible: false)
    end
  end
end