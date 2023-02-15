# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::ContentAggregator::ChildViewer::ButtonPanel::DefaultComponent, type: :component do
  subject(:component) { described_class.new(document: document, child: child, **attr) }

  let(:attr) { { child_index: 0, local_downloads: true } }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  include_context "a solr document"

  let(:document) { solr_document }
  let(:presenter) { double(Dcv::ShowPresenter) }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(view_context).to receive(:structured_children_for_document).with(document).and_return([child])
    allow(view_context).to receive(:document_presenter).and_return(presenter)
    allow(presenter).to receive(:html_title).and_return("Document Show Title")
    allow(view_context). to receive(:get_resolved_asset_info_url).and_return("/iiif/info.json")
  end

  context 'has an image child' do
    let(:child) { SolrDocument.new(id: 'child_id', dc_type: 'StillImage') }
    let(:details_url) { "/details" }

    before do
      allow(view_context).to receive(:can_access_asset?).and_return(true)
      allow(view_context). to receive(:zoom_url_for_doc).and_return(details_url)
    end
    it "has a link to open a zoom modal" do
      expect(rendered).to have_selector("a.item-modal[data-display-url ='#{details_url}']")
    end
  end
  context "child type has no aspect ratio configured" do
    let(:child) { SolrDocument.new(id: 'child_id', dc_type: 'SurpriseValue') }
    it "returns a default value" do
      expect(component.embed_aspect_ratio).to eql(described_class::DEFAULT_ASPECT_RATIO)
    end
  end
end