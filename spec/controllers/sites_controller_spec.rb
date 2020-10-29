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
		let(:search_uri) { URI(controller.search_action_url) }
		context 'catalog search' do
			it { expect(search_uri.path).to eql('/catalog') }
		end
		context 'custom search' do
			let(:site) { FactoryBot.create(:site, search_type: 'custom') }
			it do
				expect(controller).to receive(:url_for).with(controller: site.slug, action: 'index')
				controller.search_action_url
			end
		end
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it { expect(search_uri.path).to eql("/#{site.slug}/search") }
		end
	end
	describe '#tracking_method' do
		it { expect(controller.tracking_method).to eql('track_sites_path') }
	end
	describe '#site_params' do
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
	end
end
