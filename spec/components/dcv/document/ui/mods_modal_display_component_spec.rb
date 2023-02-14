# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Document::Ui::ModsModalDisplayComponent, type: :component do
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

  context "without a mods datastream" do
    it "does not render" do
      expect(component.render?).to be false
      expect(render).to be_blank
    end
  end

  context 'with a mods datastream' do
    before do
      solr_data[:datastreams_ssim] = ['descMetadata']
    end
    it "renders a button" do
      expect(rendered).to have_selector("button[data-display-url]")
    end
  end
end