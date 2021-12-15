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
end
