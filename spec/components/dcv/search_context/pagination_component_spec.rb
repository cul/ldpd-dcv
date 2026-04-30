# frozen_string_literal: true

require 'rails_helper'

describe Dcv::SearchContext::PaginationComponent, type: :component do
  subject(:component) { described_class.new(search_context: search_context, search_session: search_session) }

  # search_context may be nil or a hash of :prev and :next
  let(:search_context) { nil }

  # search_session may be nil or a hash of %w(id counter total)
  let(:search_session) { nil }


  let(:item_page_entry_info) { nil }

  before do
    allow(view_context).to receive(:item_page_entry_info).and_return(item_page_entry_info)
    allow(view_context).to receive(:current_search_session).and_return({ query_params: {}})
    allow(view_context).to receive(:link_back_to_catalog) { |arg| arg[:label] }
  end

  include_context "renderable view components"

  context "with a single document in search" do
    let(:item_page_entry_info) { "item_page_entry_info" }
    let(:search_context) { { prev: nil, next: nil } }
    let(:search_session) { { 'counter' => 1, 'id' => 'id', 'total' => 1 } }
    it 'links to the facet and shows the number of hits' do
      expect(rendered).to have_selector 'span.d-md-inline', text: item_page_entry_info
    end
  end

  context "with a transformed value" do
  end
end