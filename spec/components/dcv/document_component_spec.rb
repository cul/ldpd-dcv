# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::DocumentComponent, type: :component do
  subject(:component) { described_class.new(document: presenter, **attr) }

  let(:attr) { { document_counter: nil } }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  include_context "a solr document"

  let(:document) { solr_document }
  let(:presenter) { double(Dcv::ShowPresenter, document: document) }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(view_context).to receive(:document_presenter).and_return(presenter)
    allow(presenter).to receive(:html_title).and_return("Document Show Title")
  end

  context "has a document_counter" do
    let(:page_size) { 20 }
    let(:document_counter) { (1..page_size).to_a.shuffle.first }
    let(:offset) { page_size * (0..9).to_a.shuffle.first }
    let(:attr) { { document_counter: document_counter, counter_offset: offset } }
    let(:search_session) { { 'per_page' => page_size } }
    let(:session_id) { (1..100).to_a.shuffle.first }
    let(:current_search_session) { double(Search, id: session_id) }
    before do
      component.instance_variable_set(:@view_context, view_context)
      allow(view_context).to receive(:current_search_session).and_return(current_search_session)
      allow(view_context).to receive(:search_session).and_return(search_session)
    end
    it "includes counter in the document_link_params" do
      expect(view_context).to receive(:session_tracking_params).with(document, document_counter + offset).and_return({})
      component.document_link_params
    end
  end

  describe '#short_title' do
    let(:long_title) { '0123456789abcdefghijklmnopqrstuvwxyz' }
    let(:short_title) { '0123456789abc' }
    let(:document) { { 'title_ssm' => title_value } }
    let(:view_context) { Struct.new(:document_index_view_type).new(:index) }
    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:presenter) { double(Dcv::ShowPresenter, document: document, heading: title_value) }
    subject { component.short_title }

    context "a short title" do
      let(:title_value) { short_title }
      it { is_expected.to eql(short_title) }
    end

    context "a long title" do
      let(:title_value) { long_title }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end

    context "a long title in an array" do
      let(:title_value) { [long_title] }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end

    context "no title" do
      let(:title_value) { nil }
      let(:document) { { 'some_field' => 'some_value' } }
      it { is_expected.to be_nil }
    end
  end
end