require 'rails_helper'

describe Sites::PagesController, type: :unit do
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
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
	end
	describe '#search_action_url' do
		let(:query) { {search_field: 'all_text_teim'} }
		let(:search_uri) { URI(controller.search_action_url(query)) }
		context 'catalog search' do
			it { expect(search_uri.path).to eql('/catalog') }
			it { expect(search_uri.query).to match(/search_field\=/) }
		end
		context 'custom search' do
			let(:site) { FactoryBot.create(:site, search_type: 'custom') }
			it do
				expect(controller).to receive(:url_for).with(controller: site.slug, action: 'index')
				controller.search_action_url
			end
			it do
				expect(controller).to receive(:url_for).with(query.merge(controller: site.slug, action: 'index'))
				controller.search_action_url(query)
			end
		end
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it { expect(search_uri.path).to eql("/#{site.slug}/search") }
			it { expect(search_uri.query).to match(/search_field\=/) }
		end
	end
	describe '#update' do
		let(:page_title) { 'Example Title' }
		let(:page) { FactoryBot.create(:site_page, site_id: site, title: page_title) }
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site.slug,
				slug: page.slug,
				site_page: {
					use_multiple_columns: 'true'
				}
			)
		}
		before do
			controller.instance_variable_set(:@subsite, site)
			controller.instance_variable_set(:@page, page)
			allow(controller).to receive(:load_page).and_return(page)
			allow(controller).to receive(:flash).and_return({})
		end
		it "updates submitted attributes from sanitized values and redirects" do
			expect(page).to receive(:update_attributes).with(columns: 2)
			expect(controller).to receive(:redirect_to).with("/#{site.slug}/#{page.slug}/edit")
			controller.update
		end
	end
end
