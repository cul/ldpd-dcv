require 'rails_helper'

describe Dcv::Sites::SearchUrlService, type: :unit do
	describe '#search_action_url' do
		let(:controller) { double(Sites::SearchController) }
		let(:query) { {search_field: 'all_text_teim'} }
		let(:search_url_service) { described_class.new }
		context 'catalog search' do
			let(:site) { FactoryBot.create(:site, search_type: 'catalog') }
			let(:collection_filter) { { "lib_collection_sim"=>["DLC Site Collection"] } }
			let(:repo_filter) { { "lib_repo_code_ssim"=>["NNC-RB"] } }
			let(:expected_filters) { collection_filter }
			let(:expected_url_params) do
				query.merge(controller: '/catalog', action: 'index', f: expected_filters)
			end
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				search_url_service.search_action_url(site, controller, query)
			end
			context 'restricted' do
				let(:site) { FactoryBot.create(:site, slug: "/restricted/site", repository_id: 'NNC-RB', restricted: true) }
				let(:expected_filters) { collection_filter.merge(repo_filter) }
				let(:expected_url_params) do
					query.merge(controller: '/repositories/catalog', repository_id: 'NNC-RB', f: expected_filters, action: 'index')
				end
				it do
					expect(controller).to receive(:url_for).with(expected_url_params)
					search_url_service.search_action_url(site, controller, query)
				end
			end
		end
		context 'custom search' do
			let(:site) { FactoryBot.create(:site, search_type: 'custom') }
			it do
				expect(controller).to receive(:url_for).with(controller: site.slug, action: 'index')
				search_url_service.search_action_url(site, controller)
			end
			it do
				expect(controller).to receive(:url_for).with(query.merge(controller: site.slug, action: 'index'))
				search_url_service.search_action_url(site, controller, query)
			end
		end
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			let(:expected_url_params) { query.merge(controller: '/sites/search', action: 'index', site_slug: site.slug) }
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				search_url_service.search_action_url(site, controller, query)
			end
		end
	end
end
