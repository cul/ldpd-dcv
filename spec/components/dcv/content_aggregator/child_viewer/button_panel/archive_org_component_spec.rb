# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::ContentAggregator::ChildViewer::ButtonPanel::ArchiveOrgComponent, type: :component do
  subject(:component) { described_class.new(document: document, child: child, **attr) }

  let(:attr) { {} }
  let(:child_adapter) { Dcv::Solr::ChildrenAdapter.new(nil, nil) }
  let(:child) { child_adapter.from_archive_org_identifiers(document).first }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  include_context "a solr document"

  let(:document) { solr_document }
  let(:archive_org_url) { "https://archive.org/stream/#{archive_org_id}?ui=full&showNavbar=false" }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(view_context).to receive(:structured_children_for_document).with(document).and_return([])
    allow(view_context).to receive(:document_show_html_title).and_return("Document Show Title")
  end

  context 'has an archive.org id' do
    context 'explicitly defined' do
      include_context "indexed with a archive.org id"

      it "has a link to open a zoom modal" do
        expect(rendered).to have_selector("a.item-modal[data-display-url ='#{archive_org_url}']")
      end
    end
  end
end