require 'rails_helper'

describe PagesController, type: :controller do
  let(:default_catalog_styles) { ["gallery-#{Dcv::Sites::Constants.default_palette}", "catalog"] }

  before do
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
  end

  describe '#subsite_key' do
    it { expect(controller.subsite_key).to eql "catalog" }
  end

  shared_examples "a functioning pages controller" do
    describe '#about' do
      render_views

      let(:view_context) { controller.view_context }
      let(:total_dcv_object_count) { 200 }

      before do
        allow(controller).to receive(:view_context).and_return(view_context)
        allow(view_context).to receive(:total_dcv_object_count).and_return(total_dcv_object_count)
        allow(view_context).to receive(:current_user).and_return(nil)
      end

      it "responds" do
        get :about, params: {}
        expect(response.status).to eq(200)
        expect(response.body).to include("#{total_dcv_object_count} unique items")
      end
    end
  end

  context 'catalog site is for some reason absent' do
    describe '#subsite_styles' do
      it { expect(controller.subsite_styles).to contain_exactly *default_catalog_styles }
    end
    it_behaves_like "a functioning pages controller"
  end

  context 'catalog site entity exists' do
    let(:site_attr) { { slug: 'catalog', layout: 'default', palette: 'default' } }

    before do
      FactoryBot.create(:site, **site_attr)
    end

    describe '#subsite_styles' do
      it { expect(controller.load_subsite.slug).to eql 'catalog' }
      it { expect(controller.subsite_config).to be_present }
      it { expect(controller.subsite_styles).to contain_exactly *default_catalog_styles }
    end

    it_behaves_like "a functioning pages controller"

    context "with configured palette and layout" do
      let(:site_attr) { { slug: 'catalog', layout: 'signature', palette: 'monochromeDark' } }
      let(:expected_catalog_styles) { ["signature-monochromeDark", "catalog"] }

      describe '#subsite_styles' do
        it { expect(controller.load_subsite.slug).to eql 'catalog' }
        it { expect(controller.subsite_config).to be_present }
        it { expect(controller.subsite_styles).to contain_exactly *default_catalog_styles }
      end

      it_behaves_like "a functioning pages controller"
    end
  end
end
