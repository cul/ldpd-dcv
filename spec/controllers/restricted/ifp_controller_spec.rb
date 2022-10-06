require 'rails_helper'

describe Restricted::IfpController, :type => :controller do
  describe '#subsite_styles' do
    let(:api_key) { nil }
    before do
      FactoryBot.create(:site, slug: 'restricted/ifp', layout: 'custom', palette: 'custom')
    end
    it "includes both the common styles and custom styles" do
      expect(controller.load_subsite.layout).to eql('custom')
      expect(controller.subsite_layout).to eql('signature')
      expect(controller.subsite_styles).to eql(['signature-monochrome', 'ifp'])
    end
  end
  describe '#index' do
    context 'request for homepage' do
      let(:params) { {} }
      let(:search_service) { double(Blacklight::SearchService) }
      let(:search_results) do
        [
          [{}, []],
          [{}, []]
        ]  
      end
      before do
        allow(controller).to receive(:search_service).and_return(search_service)
        # mock get_search_results
        allow(search_service).to receive(:search_results).and_return(search_results)
        allow_any_instance_of(Blacklight::Catalog).to receive(:search_results).and_return(search_results)
      end
      it "responds successfully" do
        # skip access control related to cul_omniauth/roles.yml
        allow(controller).to receive(:store_unless_user).and_return nil
        allow(controller).to receive(:authorize_action).and_return true
        get :index, params: params
        expect(response.status).to eq(200)
      end
    end
  end
end
