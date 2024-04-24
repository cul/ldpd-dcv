require 'rails_helper'
describe Iiif::Canvas do
	let(:solr_document) { SolrDocument.new(solr_data) }
	let(:id) { "http://localhost/item" }
	let(:route_helper) { instance_double(Iiif::PresentationsController) }
	let(:manifest_routing_opts) { { collection: false } }
	let(:label) { "some label" }
	subject(:canvas) { described_class.new(id: id, solr_document: solr_document, route_helper: route_helper, ability_helper: route_helper, manifest_routing_opts: manifest_routing_opts, label: label) }

	describe '#dimensions' do
		context "in rels_int" do
			let(:solr_data) { { rels_int_profile_tesim: [JSON.generate({ 'test:gr/content' => { 'image_width' => 200, 'image_length' => 300}})] } }
			it do
				expect(canvas.dimensions).to include(width: 200, height: 300)
			end
		end
		context "from fields" do
			let(:solr_data) { { 'image_width_isi': 200, 'image_height_isi': 300 } }
			it do
				expect(canvas.dimensions).to include(width: 200, height: 300)
			end
		end
	end

	describe '#streamable?' do
		let(:solr_data) { { dc_type_ssm: [dc_type] } }
		subject(:streamable) { canvas.streamable? }

		context 'canvas type is Image' do
			let(:dc_type) { 'Image' }
			it { is_expected.to be false }
		end
		context 'canvas type is MovingImage' do
			let(:dc_type) { 'MovingImage' }
			it { is_expected.to be true }
		end
		context 'canvas type is sound' do
			let(:dc_type) { 'Sound' }
			it { is_expected.to be true }
		end
		context 'canvas type is Text' do
			let(:dc_type) { 'Text' }
			it { is_expected.to be false }
		end
	end
end