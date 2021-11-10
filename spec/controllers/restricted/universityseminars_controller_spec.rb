require 'rails_helper'

describe Restricted::UniversityseminarsController, :type => :controller do
  describe '#subsite_styles' do
    let(:api_key) { nil }
    before do
      FactoryBot.create(:site, slug: 'restricted/universityseminars', layout: 'custom', palette: 'custom')
    end
    it "includes both the common styles and custom styles" do
      expect(controller.load_subsite.layout).to eql('custom')
      expect(controller.subsite_layout).to eql('signature')
      expect(controller.subsite_styles).to eql(['signature-glacier', 'universityseminars'])
    end
  end
end
