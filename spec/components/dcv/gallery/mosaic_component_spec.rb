# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Gallery::MosaicComponent, type: :component do
  subject(:component) { described_class.new(page: page) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:page) { FactoryBot.create(:site_page, site: FactoryBot.create(:site)) }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
  end

  context 'when less than the requested number of featured items are available' do
    let(:limited_ids) { ['a', 'b', 'c'] }
    let(:solr_docs) { limited_ids.map { |id| SolrDocument.new(id: id, ezid_doi_ssim: ["http://www.#{id}.org"]) } }
    let(:expected_ids) { ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c', 'a', 'b'] }
    before do
      allow(controller).to receive(:featured_items).and_return(solr_docs)
      render
    end
    it "pads the featured item list with repeats" do
      expect(component.featured_items.map(&:id)).to eql(expected_ids)
    end
  end

  context 'when requesting featured items raises an error' do
    before do
      allow(controller).to receive(:featured_items).and_raise("an error")
      render
    end
    it 'fails gracefully' do
      expect(component.render?).to be false
    end
  end
end