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
	let(:edit_site_page_path) { "/#{site.slug}/#{page.slug}/edit" }
	let(:edit_site_path) { "/#{site.slug}/edit" }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
	end
	include_context 'verify configurable layouts'
	describe '#search_action_url' do
		let(:query) { {search_field: 'all_text_teim'} }
		let(:collection_filter) { { "lib_collection_sim"=>["DLC Site Collection"] } }
		let(:repo_filter) { { "lib_repo_code_ssim"=>["NNC-RB"] } }
		context 'catalog search' do
			let(:expected_filters) { collection_filter }
			let(:expected_url_params) do
				query.merge(controller: '/catalog', action: 'index', f: expected_filters)
			end
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				controller.search_action_url(query)
			end
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
			let(:expected_url_params) { query.merge(controller: 'sites/search', action: 'index', site_slug: site.slug) }
			it do
				expect(controller).to receive(:url_for).with(query.merge(controller: 'sites/search', action: 'index', site_slug: site.slug))
				controller.search_action_url(query)
			end
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
			allow(controller).to receive(:edit_site_page_path).and_return(edit_site_page_path)
		end
		it "updates submitted attributes from sanitized values and redirects" do
			expected_atts = ActionController::Parameters.new(columns: 2).permit(:columns)
			expect(page).to receive(:update_attributes!).with(expected_atts)
			expect(controller).to receive(:redirect_to).with(edit_site_page_path)
			controller.update
		end
		context 'home page' do
			let(:page) { FactoryBot.create(:site_page, site_id: site, title: page_title, slug: 'home') }
			let(:flash) { {} }
			let(:params) {
				ActionController::Parameters.new(
					site_slug: site.slug,
					slug: page.slug,
					site_page: {
						slug: 'nothome',
						use_multiple_columns: 'true'
					}
				)
			}
			before do
				allow(controller).to receive(:flash).and_return(flash)
			end
			it "rejects submitted changes to slug" do
				expect(controller).to receive(:redirect_to).with(edit_site_page_path)
				controller.update
				expect(page.changed?).to be
				page.reload
				expect(flash[:alert]).to include('home')
				expect(page.slug).to eql('home')
			end
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
			allow(controller).to receive(:edit_site_path).and_return(edit_site_path)			
		end
		context "home page" do
			let(:page_slug) { 'home' }
			it "does not destroy, sets flash message, and redirects to site edit" do
				expect(page).not_to receive(:destroy)
				expect(controller).to receive(:redirect_to).with(edit_site_path)
				controller.destroy
				expect(flash[:alert]).to include(page_slug)
			end
		end
		context "other pages" do
			let(:page_slug) { 'notHome' }
			it "destroys page, sets flash message, and redirects to site edit" do
				expect(page).to receive(:destroy)
				expect(controller).to receive(:redirect_to).with(edit_site_path)
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
