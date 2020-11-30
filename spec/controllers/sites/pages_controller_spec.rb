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
			expect(page).to receive(:update_attributes!).with(columns: 2)
			expect(controller).to receive(:redirect_to).with("/#{site.slug}/#{page.slug}/edit")
			controller.update
		end
	end
	describe '#destroy' do
		let(:page_title) { 'Example Title' }
		let(:page) { FactoryBot.create(:site_page, site_id: site, title: page_title, slug: page_slug) }
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site.slug,
				slug: page.slug,
			)
		}
		let(:flash) { {} }
		before do
			controller.instance_variable_set(:@subsite, site)
			controller.instance_variable_set(:@page, page)
			allow(controller).to receive(:load_page).and_return(page)
			allow(controller).to receive(:flash).and_return(flash)
		end
		context "home page" do
			let(:page_slug) { 'home' }
			it "does not destroy, sets flash message, and redirects to site edit" do
				expect(page).not_to receive(:destroy)
				expect(controller).to receive(:redirect_to).with("/#{site.slug}/edit")
				controller.destroy
				expect(flash[:alert]).to include(page_slug)
			end
		end
		context "other pages" do
			let(:page_slug) { 'notHome' }
			it "destroys page, sets flash message, and redirects to site edit" do
				expect(page).to receive(:destroy)
				expect(controller).to receive(:redirect_to).with("/#{site.slug}/edit")
				controller.destroy
				expect(flash[:notice]).to include(page_slug)
			end
		end
	end
	describe '#show' do
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site_slug,
				slug: page_slug
			)
		}
		let(:site_slug) { 'siteSlug' }
		let(:page_slug) { 'pageSlug' }
		before do
			controller.instance_variable_set(:@subsite, site)
			controller.instance_variable_set(:@page, page)
			allow(controller).to receive(:load_site).and_return(site)
		end
		context 'site is non-existent' do
			let(:site) { nil }
			let(:page) { nil }
			it "returns a 404" do
				expect(controller).to receive(:render).with(status: :not_found, layout: false, file: "#{Rails.root}/public/404.html")
				controller.show
			end
		end
		context 'page is non-existent' do
			let(:site) { FactoryBot.create(:site, slug: site_slug) }
			let(:page) { nil }
			it "returns a 404" do
				expect(controller).to receive(:render).with(status: :not_found, layout: false, file: "#{Rails.root}/public/404.html")
				controller.show
			end
		end
	end
end
