require 'rails_helper'

describe Dcv::Sites::SearchState, type: :unit do
	let(:site_slug) { 'show_route_factory' }
	let(:site_search_type) { Dcv::Sites::Constants::SEARCH_LOCAL }
	let(:doi_id) { '10.12345/1a2b3c-4d5e' }
	let(:search_controller_path) { 'sites/search' }
	let(:blacklight_config) { instance_double(Blacklight::Configuration) }
	let(:params) { { site_slug: site_slug } }
	let(:search_state) { described_class.new(params, blacklight_config, controller) }
	shared_examples "a correctly linking search state" do
		let(:site_attrs) { { slug: site_slug, search_type: site_search_type } }
		let(:site) { FactoryBot.create(:site, **site_attrs) }

		before do
			allow(controller).to receive(:load_subsite).and_return(site)
			allow(controller).to receive(:restricted?).and_return(false)
		end

		describe '#url_for_document' do
			subject(:url_params) { search_state.url_for_document(document) }
			context 'slugged site' do
				let(:document) { { 'slug_ssim' => [site_slug] } }
				it { is_expected.to include('slug' => site_slug) }
			end
			context 'doi document' do
				let(:document) { { 'ezid_doi_ssim' => ["doi:#{doi_id}"] } }
				it { is_expected.to include('site_slug' => site_slug, 'id' => doi_id) }
				context 'and a delegated search' do
					let(:site_search_type) { Dcv::Sites::Constants::SEARCH_CATALOG }
					it { is_expected.to include('controller' => 'catalog', 'id' => doi_id) }
				end
			end
		end
	end

	context "from the SitesController show view (home page)" do
		let(:controller) { instance_double(SitesController, controller_path: 'sites') }
		it_behaves_like "a correctly linking search state"
	end

	context "from the Sites::SearchController index view (search page)" do
		let(:controller) { instance_double(Sites::SearchController, controller_path: search_controller_path) }
		it_behaves_like "a correctly linking search state"
	end
end
