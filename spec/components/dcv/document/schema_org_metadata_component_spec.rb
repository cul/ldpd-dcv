# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Document::SchemaOrgMetadataComponent, type: :component do
  subject(:component) { described_class.new(document: document) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  include_context "a solr document"

  let(:document) { solr_document }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
  end

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