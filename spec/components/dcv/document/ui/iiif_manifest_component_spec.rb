# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Document::Ui::IiifManifestComponent, type: :component do
  subject(:component) { described_class.new(document: document) }

  include_context "a solr document"

  include_context "renderable view components"

  let(:document) { solr_document }
  let(:child) { nil }

  before do
    allow(view_context).to receive(:structured_children_for_document).with(document).and_return([child].compact)
    render
  end

  context "without a DOI" do
    it "does not render" do
      expect(component.render?).to be false
      expect(render).to be_blank
    end
  end

  context 'with a DOI' do
    include_context "indexed with a doi"

    context "with Collection active_fedora_model" do
      let(:active_fedora_model) { 'Collection' }

      it "renders a button" do
        expect(rendered).to have_selector("a#draggable-iiif-button")
      end
    end

    context "with ContentAggregator active_fedora_model" do
      let(:active_fedora_model) { 'ContentAggregator' }

      context 'no children' do
        it "does not render" do
          expect(component.render?).to be false
          expect(render).to be_blank
        end
      end

      context 'has an image child' do
        let(:child) { SolrDocument.new(id: 'child_id', dc_type: 'StillImage') }
        it "renders a button" do
          expect(rendered).to have_selector("a#draggable-iiif-button")
        end
      end
    end

    context "with GenericResource active_fedora_model" do
      let(:active_fedora_model) { 'GenericResource' }

      context "with non-image dc:type" do
        let(:types) { ["MovingImage"] }
        it "does not render" do
          expect(component.render?).to be false
          expect(render).to be_blank
        end        
      end

      context "with dc:type StillImage" do
        let(:types) { ["StillImage"] }

        it "renders a button" do
          expect(rendered).to have_selector("a#draggable-iiif-button")
        end
      end
    end
  end
end