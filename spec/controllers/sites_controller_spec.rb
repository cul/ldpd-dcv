require 'rails_helper'

describe SitesController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
			slug: site.slug
		)
	}
	let(:site) { FactoryBot.create(:site) }
	let(:edit_site_path) { "/#{site.slug}/edit" }
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
		allow(controller).to receive(:edit_site_path).with(slug: site.slug).and_return(edit_site_path)
	end
	include_context 'verify configurable layouts'
	describe '.site_as_solr_document' do
		it "generates a solr document" do
			expect(described_class.site_as_solr_document(site).fetch(:slug_ssim)).to eql([site.slug])
		end
	end
	describe '#search_action_url' do
		let(:query) { {search_field: 'all_text_teim'} }
		let(:search_uri) { URI(controller.search_action_url(query)) }
		context 'catalog search' do
			let(:collection_filter) { { "lib_collection_sim"=>["DLC Site Collection"] } }
			let(:repo_filter) { { "lib_repo_code_ssim"=>["NNC-RB"] } }
			let(:expected_filters) { collection_filter }
			let(:expected_url_params) do
				query.merge(controller: '/catalog', action: 'index', f: expected_filters)
			end
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				controller.search_action_url(query)
			end
			context 'restricted' do
				let(:site) { FactoryBot.create(:site, slug: "/restricted/site", repository_id: 'NNC-RB', restricted: true) }
				let(:expected_filters) { collection_filter.merge(repo_filter) }
				let(:expected_url_params) do
					query.merge(controller: '/repositories/catalog', repository_id: 'NNC-RB', f: expected_filters, action: 'index')
				end
				it do
					expect(controller).to receive(:url_for).with(expected_url_params)
					controller.search_action_url(query)
				end
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
			let(:expected_url_params) { query.merge(controller: '/sites/search', action: 'index', site_slug: site.slug) }
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				controller.search_action_url(query)
			end
		end
	end
	describe '#search_facet_path' do
		context 'local search' do
			let(:query) { {id: 'format_ssim'} }
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			let(:expected_url_params) { query.merge(controller: '/sites/search', action: 'facet', site_slug: site.slug, only_path: true) }
			it do
				expect(controller).to receive(:url_for).with(expected_url_params)
				controller.search_facet_path(query)
			end
		end
	end
	describe '#tracking_method' do
		it { expect(controller.tracking_method).to eql('sites_track_path') }
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
				allow(controller).to receive(:redirect_to).with(edit_site_path)
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
