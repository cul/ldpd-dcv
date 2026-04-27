# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Document::Ui::ModsModalDisplayComponent, type: :component do
  subject(:component) { described_class.new(document: document) }

  def vc_test_controller_class
    controller
  end

  include_context "renderable view components"

  include_context "a solr document"

  let(:document) { solr_document }



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