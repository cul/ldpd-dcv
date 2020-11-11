require 'rails_helper'

describe SitesController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
			slug: site.slug
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
	describe '#tracking_method' do
		it { expect(controller.tracking_method).to eql('track_sites_path') }
	end
	describe '#site_params' do
		let(:is_admin) { false }
		before do
			controller.instance_variable_set(:@subsite, site)
			allow(controller).to receive(:can?).with(:admin, site).and_return(is_admin)
		end
		context 'with blank image_uris values' do
			let(:params) {
				ActionController::Parameters.new(
					site: {
						image_uris: ['a', nil, 'b', '', 'c']
					}
				)
			}
			let(:update_params) { controller.send :site_params }
			it "compacts the values" do
				expect(update_params[:image_uris]).to eql(['a', 'b', 'c'])
			end
		end
		context 'with editor_uids text' do
			let(:uids) { ['abc', 'bcd', 'cde'] }
			let(:params) {
				ActionController::Parameters.new(
					site: {
						editor_uids: uids.join("\n ,")
					}
				)
			}
			let(:update_params) { controller.send :site_params }
			context 'with admin' do
				let(:is_admin) { true }
				it "parses the value array" do
					expect(update_params[:editor_uids]).to eql(uids)
				end
			end
			context 'not admin' do
				it "removes proposed values" do
					expect(update_params[:editor_uids]).to eql(site.editor_uids)
				end
			end
		end
	end
end
