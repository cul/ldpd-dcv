require 'rails_helper'

describe Repositories::CatalogController, type: :controller do
  let(:default_catalog_styles) { ["gallery-#{Dcv::Sites::Constants.default_palette}", "catalog"] }
  let(:view_context) { controller.view_context }
  let(:site_attr) { { slug: 'NNC-RB', layout: 'default', palette: 'monochrome', search_type: Site::SEARCH_REPOSITORIES } }
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:subsite) { FactoryBot.create(:site, **site_attr) }

  before do
    expect(subsite).not_to be_nil
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
    controller.set_view_path
    allow(controller).to receive(:search_service).and_return(search_service)
    allow(search_service).to receive(:search_results)
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(view_context).to receive(:current_user).and_return(nil)
  end

  after do
    subsite.destroy
  end

  describe '#index' do
    it "responds" do
      get :index, params: { repository_id: 'NNC-RB' }
      expect(response.status).to eq(200)
      expect(controller.load_subsite.palette).to eql 'monochrome'
    end
    it "has robots meta flag attributes" do
      get :index, params: { repository_id: 'NNC-RB' }
      expect(controller.instance_variable_get(:@meta_nofollow)).to be true
      expect(controller.instance_variable_get(:@meta_noindex)).to be true
    end
  end
end
