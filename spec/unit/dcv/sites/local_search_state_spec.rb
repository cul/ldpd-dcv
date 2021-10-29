require 'rails_helper'

describe Dcv::Sites::LocalSearchState, type: :unit do
	let(:site_slug) { 'show_route_factory' }
	let(:doi_id) { '10.12345/1a2b3c-4d5e' }
	let(:document) { { 'ezid_doi_ssim' => ["doi:#{doi_id}"] } }
	let(:controller) { instance_double(Sites::SearchController, controller_name: 'sites/search') }
	let(:blacklight_config) { instance_double(Blacklight::Configuration) }
	let(:params) { { site_slug: site_slug } }
	let(:search_state) { described_class.new(params, blacklight_config, controller) }
	describe '#url_for_document' do
		subject(:url_params) { search_state.url_for_document(document) }
		it { is_expected.to include('site_slug' => site_slug, 'id' => doi_id) }
	end
end
