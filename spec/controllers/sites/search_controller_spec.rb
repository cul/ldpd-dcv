require 'rails_helper'

describe Sites::SearchController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
			site_slug: site.slug
		)
	}
	let(:site) { FactoryBot.create(:site) }
	let(:request_double) { instance_double('ActionDispatch::Request') }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:path_parameters).and_return({})
		controller.instance_variable_set :@subsite, site
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
	end
	include_context 'verify configurable layouts'
	describe '#search_action_url' do
		let(:query) { {search_field: 'all_text_teim'} }
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it do
				expect(controller).to receive(:site_search_url).with(site.slug, query)
				controller.search_action_url(query)
			end
		end
	end
	describe '#search_service' do
		subject(:search_service) { controller.search_service }
		it { is_expected.to be_a Dcv::SearchService }
	end
	describe '#load_subsite!' do
		context 'no site for slug' do
			let(:params) {
				ActionController::Parameters.new(
					site_slug: 'nonexistent'
				)
			}
			let(:root_url) { 'root_url' }
			let(:site) { nil }
			before { allow(controller).to receive(:root_url).and_return(root_url) }

			it 'raises ActiveRecord::RecordNotFound' do
				expect {controller.load_subsite!}.to raise_error(ActiveRecord::RecordNotFound)
			end
		end
	end
	describe '#redirect_unless_local'do
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it do
				expect(controller).not_to receive(:redirect_to)
				controller.redirect_unless_local
			end
		end
		context 'catalog search' do
			let(:search_url_service) { double(Dcv::Sites::SearchUrlService) }
			let(:well_known_url) { "/catalog?q=success" }
			let(:site) { FactoryBot.create(:site, search_type: 'catalog') }
			before do
				controller.instance_variable_set :@search_url_service, search_url_service
				allow(search_url_service).to receive(:search_action_url).and_return(well_known_url)
			end
			it do
				expect(controller).to receive(:redirect_to).with(well_known_url)
				controller.redirect_unless_local
			end
		end
	end
	describe '#legacy_redirect' do
		let(:legacy_id) { 'legacy_id' }
		let(:current_id) { 'current_id' }
		let(:solr_doc) { SolrDocument.new(id: current_id) }
		let(:solr_response) { instance_double(Blacklight::Solr::Response) }
		let(:well_known_url) { {action: "show", controller: "catalog", id: "current_id"} }
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site.slug, document_id: legacy_id
			)
		}
		before do
			allow(controller).to receive(:fetch).with(legacy_id, q: "{!raw f=identifier_ssim v=$ids}").and_return([solr_response, solr_doc])
		end
		it do
			expect(controller).to receive(:redirect_to).with(well_known_url)
			controller.legacy_redirect
		end		
	end
end
