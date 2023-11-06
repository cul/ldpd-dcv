# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::ContentAggregator::ChildViewer::SoftwareComponent, type: :component do
  subject(:component) { described_class.new(document: document, child: child, **attr) }

  let(:attr) { { child_index: 2 } }
  let(:child) { { id: "1234567", pid: "test:123" } }
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
    allow(view_context).to receive(:document_presenter).and_return(presenter)
    allow(view_context).to receive(:identifier_to_pid).and_return("test:123")
    allow(presenter).to receive(:html_title).and_return("Document Show Title")
  end
  it "renders" do
    expect(rendered). to be_present
  end
end