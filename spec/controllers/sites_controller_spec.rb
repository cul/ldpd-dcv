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
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
	end
	include_context 'verify configurable layouts'
	describe '#search_action_url' do
		let(:query) { {search_field: 'all_text_teim'} }
		let(:search_uri) { URI(controller.search_action_url(query)) }
		context 'catalog search' do
			it { expect(search_uri.path).to eql('/catalog') }
			context 'restricted' do
				let(:site) { FactoryBot.create(:site, slug: "restricted/site", repository_id: 'NNC-RB', restricted: true) }
				it { expect(search_uri.path).to eql('/NNC-RB/catalog') }
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
		context 'with nav_menus_attributes' do
			let(:params) do
				ActionController::Parameters.new(
					site: {
						nav_menus_attributes: {
							:'1' => {
								label: "Group 1",
								links_attributes: {
									:'0' => {
										label: "Link 0",
										link: "linkSlug0"
									}
								}
							}
						}
					}
				)
			end
			let(:expected) do
				{
					sort_group: "01:Group 1",
					sort_label: "00:Link 0",
					link: "linkSlug0"
				}
			end
			let(:update_params) { controller.send :site_params }
			it 'unrolls nav_menus_attributes into nav_links_attributes' do
				expect(update_params['nav_links_attributes'].first).to include(expected)
			end
		end
	end
	describe '#update' do
		before do
			controller.instance_variable_set(:@subsite, site)
			allow(controller).to receive(:can?).with(:admin, site).and_return(false)
		end
		context 'with nav_menus_attributes' do
			let(:params) do
				ActionController::Parameters.new(
					site: {
						nav_menus_attributes: {
							:'1' => {
								label: "Group 1",
								links_attributes: {
									:'0' => {
										label: "Link 0",
										link: "linkSlug0"
									}
								}
							}
						}
					}
				)
			end
			let(:expected) do
				{
					'sort_group' => "01:Group 1",
					'sort_label' => "00:Link 0",
					'link' => "linkSlug0"
				}
			end
			before do
				allow(controller).to receive(:redirect_to).with("/#{site.slug}/edit")
				controller.update
			end
			it 'unrolls nav_menus_attributes into nav_links_attributes' do
				expect(site.nav_links.first.attributes).to include(expected)
			end
		end
		context 'with image upload' do
			let(:fixture_file_path) { "sites/import/directory/images/signature.svg" }
			let(:target_path) { site.watermark_uploader.store_path }
			let(:params) do
				ActionController::Parameters.new(
					site: {
						watermark: fixture_file_upload(fixture_file_path)
					}
				)
			end
			before do
				allow(controller).to receive(:redirect_to).with("/#{site.slug}/edit")
			end
			after do
				File.delete(target_path) if File.exists?(target_path)
			end
			it 'updates/creates watermark image' do
				expect(File.exists?(target_path)).to be false
				controller.update
				expect(File.exists?(target_path)).to be true
				expect(File.read(target_path)).to eql(File.read(File.join(fixture_path, fixture_file_path)))
			end
		end
	end
end
