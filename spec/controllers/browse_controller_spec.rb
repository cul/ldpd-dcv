require 'rails_helper'

describe BrowseController, type: :controller do
  let(:default_catalog_styles) { ["gallery-#{Dcv::Sites::Constants.default_palette}", "catalog"] }
  let(:site_attr) { { slug: 'catalog', layout: 'default', palette: 'default' } }
  let(:site) { FactoryBot.create(:site, **site_attr) }
  let(:view_context) { controller.view_context }

  before do
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
    allow(controller).to receive(:view_context).and_return(view_context)
    expect(site.slug).to eql(controller.load_subsite&.slug)
    view_context.instance_variable_set(:@subsite, site)
  end

  after do
    site&.destroy
    controller.instance_variable_set(:@subsite, nil)
  end

  describe '#subsite_key' do
    it { expect(controller.subsite_key).to eql "catalog" }
  end

  shared_examples "a functioning browse controller" do
    describe '#about', js: true do
      render_views

      let(:test_format) { 'Test' }
      let(:test_format_count) { 200 }
      let(:format_link) { "<a href=\"/catalog?f%5Blib_format_sim%5D%5B%5D=#{test_format}\">#{test_format}</a>"}
      let(:formats_fixture) do
        {
          'lib_format_sim' => {
            'value_pairs' => [
              [test_format, test_format_count]
            ]
          }
        }
      end

      before do
        allow(view_context).to receive(:current_user).and_return(nil)
        expect(controller).to receive(:get_catalog_browse_lists).and_return(formats_fixture)
        # controller expectations verified, we can assign to the cached view_context
        view_context.instance_variable_set(:@browse_lists, formats_fixture)
      end

      it "responds" do
        get :list, params: { list_id: 'formats' }
        expect(response.status).to eq(200)
        expect(response.body).to include("#{format_link} (#{test_format_count})")
      end
      it "has robots meta flag attributes" do
        get :list, params: { list_id: 'formats' }
        expect(controller.instance_variable_get(:@meta_noindex)).to be true
        expect(controller.instance_variable_get(:@meta_nofollow)).to be true
      end
    end
  end

  context 'catalog site is for some reason absent' do
    describe '#subsite_styles' do
      it { expect(controller.subsite_styles).to contain_exactly *default_catalog_styles }
    end
    it_behaves_like "a functioning browse controller"
  end

  context 'catalog site entity exists' do
    describe '#subsite_styles' do
      it { expect(controller.load_subsite.slug).to eql 'catalog' }
      it { expect(controller.subsite_config).to be_present }
      it { expect(controller.subsite_styles).to contain_exactly *default_catalog_styles }
    end

    it_behaves_like "a functioning browse controller"

    context "with configured palette and layout" do
      let(:site_attr) { { slug: 'catalog', layout: 'signature', palette: 'monochromeDark' } }
      let(:expected_catalog_styles) { ["signature-monochromeDark", "catalog"] }

      describe '#subsite_styles' do
        it { expect(controller.load_subsite.slug).to eql 'catalog' }
        it { expect(controller.subsite_config).to be_present }
        it { expect(controller.subsite_styles).to contain_exactly *expected_catalog_styles }
      end

      it_behaves_like "a functioning browse controller"
    end
  end
end
