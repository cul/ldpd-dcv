require 'rails_helper'

describe Dcv::SearchState, type: :unit do
	let(:site_slug) { 'show_route_factory' }
	let(:doi_id) { '10.12345/1a2b3c-4d5e' }
	let(:document) { { 'ezid_doi_ssim' => ["doi:#{doi_id}"] } }
	let(:controller) { instance_double(Sites::SearchController, controller_name: 'sites/search') }
	let(:blacklight_config) { instance_double(Blacklight::Configuration) }
	let(:params) { { site_slug: site_slug } }
	let(:search_state) { described_class.new(params, blacklight_config, controller) }
	describe '#url_for_document' do
		subject(:url_params) { search_state.url_for_document(document) }
	end
	describe '#url_for_document' do
		let(:slug) { 'sluggo' }
		let(:document_show_link_field) { 'title_short' }
		subject(:url_params) { search_state.url_for_document(document) }
		context 'with a site result' do
			let(:document) do
				{
				'title_short' => '0123456789abc',
				'title_long' => '0123456789abcdefghijklmnopqrstuvwxyz',
				'title_long_array' => ['0123456789abcdefghijklmnopqrstuvwxyz'],
				'dc_type_ssm' => ['Publish Target'],
				'slug_ssim' => [slug]
				}
			end
			let(:expected_url_params) { { 'controller' => 'sites', 'action' => 'home', 'slug' => slug } }
			it { is_expected.to eql(expected_url_params) }
			context 'that is nested' do
				let(:slug) { 'nancy/sluggo' }
				it { is_expected.to eql(expected_url_params) }
			end
		end
	end
end
