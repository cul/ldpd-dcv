require 'rails_helper'

describe PagesController, type: :controller do
  let(:default_catalog_styles) { ["gallery-#{Dcv::Sites::Constants.default_palette}", "catalog"] }
  let(:view_context) { controller.view_context }
  let(:site_attr) { { slug: 'catalog', layout: 'default', palette: 'default' } }
  let(:subsite) { FactoryBot.create(:site, **site_attr) }

  before do
    expect(subsite).not_to be_nil
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
    controller.set_view_path
    #expect(controller.instance_variable_get(:@subsite)).not_to be_nil
    allow(controller).to receive(:view_context).and_return(view_context)
    allow(view_context).to receive(:current_user).and_return(nil)
  end

  after do
    subsite.destroy
    described_class.instance_variable_set(:@subsite, nil)
  end

  describe '#subsite_key' do
    it { expect(controller.subsite_key).to eql "catalog" }
  end

  shared_examples "a functioning pages controller" do
    describe '#about' do
      render_views

      let(:total_dcv_object_count) { 200 }

      before do
        allow(view_context).to receive(:total_dcv_object_count).and_return(total_dcv_object_count)    
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
        it { expect(controller.subsite_styles).to contain_exactly *expected_catalog_styles }
      end

      it_behaves_like "a functioning pages controller"
    end
  end

  describe '#tombstone' do
    render_views

    let(:fake_doi) { "10.7916/fake-doi" }
    let(:datacite_url) { "https://commons.datacite.org/doi.org?query=#{URI.encode_www_form_component(fake_doi)}" }
    let(:datacite_link) { "<a href=\"#{datacite_url}\">Datacite</a>" }
    it "links to Datacite" do
      get :tombstone, params: { id: fake_doi }
      expect(response.body).to include(datacite_link)
    end
  end
end
