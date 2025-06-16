require 'rails_helper'
describe Iiif::Collection::ArchivesSpaceCollection do
	let(:archives_space_id) { '7cbce73e9905b341c94d4bd4b3c1fc79' }
	let(:ability_helper) do
		TestAbilityHelper.new
	end
	let(:route_helper) do
		TestRouteHelper.new
	end
	let(:children_service) { instance_double(Dcv::Solr::ChildrenAdapter) }
	let(:collection_id) do
		route_helper.iiif_aspace_collection_url(archives_space_id: archives_space_id)
	end
	let(:iiif_collection) { described_class.new(id: collection_id, children_service: children_service, ability_helper: ability_helper, route_helper: route_helper) }

	let(:xml_src) { fixture(File.join("mods", "mods-aspace-ids.xml")) }
	let(:ng_xml) { Nokogiri::XML(xml_src.read) }
	let(:adapter) { Dcv::Solr::DocumentAdapter::ModsXml.new(ng_xml) }
	let(:item_doi) { "#{item_doi_registrant}/#{item_doi_id}" }
	let(:item_doi_registrant) { '10.7916' }
	let(:item_doi_id) { 'abcdef' }
	let(:item_manifest_id) { route_helper.iiif_aspace_collected_manifest_url(archives_space_id: archives_space_id, manifest_registrant: item_doi_registrant, manifest_doi: item_doi_id) }
	let(:collection_item) { SolrDocument.new(adapter.to_solr.merge(ezid_doi_ssim: [item_doi])) }

	before do
		allow(children_service).to receive(:from_aspace_parent).with(archives_space_id).and_return([collection_item])
	end

	describe '#archives_space_id' do
		it 'parses the aspace idenitifer from the id URI' do
			expect(iiif_collection.archives_space_id).to eql(archives_space_id)
		end
	end

	describe '#label' do
		let(:xml_src) { fixture(File.join("mods", "mods-aspace-ids.xml")) }
		let(:actual) { iiif_collection.label&.[](:en) }
		let(:json_value) { iiif_collection.as_json.dig('label', :en) }

		it "sets an array of values" do
			iiif_collection.label&.[](:en)
			expect(actual).to be_a Array
			expect(actual.first).to eql("Italian Jewish Community Regulations. Series I: Ferrara (Italy). Subseries I.D Noise Regulations")
			expect(json_value.first).to eql("Italian Jewish Community Regulations. Series I: Ferrara (Italy). Subseries I.D Noise Regulations")
		end
		context 'has an item in scope' do
			let(:collection_item) { SolrDocument.new(adapter.to_solr.merge(ezid_doi_ssim: [item_doi])) }
			let(:collection_item_2) { SolrDocument.new(adapter.to_solr.merge(ezid_doi_ssim: [item_doi])) }
			before do
				allow(children_service).to receive(:from_aspace_parent).with(archives_space_id).and_return([collection_item, collection_item_2])
			end

			it 'delegates to children_service for structured list' do
				expect(iiif_collection.items).not_to be_empty
				expect(iiif_collection.items[0].instance_variable_get(:@part_of)&.first).to include('id' => collection_id)
				expect(iiif_collection.items[0].instance_variable_get(:@id)).to eq(item_manifest_id)
			end
		end
  	end

	describe '#items' do
		it 'delegates to children_service for structured list' do
			expect(children_service).to receive(:from_aspace_parent).with(archives_space_id).and_return([collection_item])
			expect(iiif_collection.items).not_to be_empty
			expect(iiif_collection.items[0].instance_variable_get(:@part_of)&.first).to include('id' => collection_id)
			expect(iiif_collection.items[0].instance_variable_get(:@id)).to eq(item_manifest_id)
		end
	end

	describe 'collection_for?' do
		let(:archives_space_parent_id) { archives_space_id }
		let(:solr_document) { SolrDocument.new({FieldDisplayHelpers::ASPACE_PARENT_FIELD => [archives_space_parent_id]}) }
		let(:result) { iiif_collection.collection_for?(solr_document) }
		it 'returns true if doc has aspace id in parent field' do
			expect(result).to be true		
		end
		context 'doc does not have aspace id in parent field' do
			let(:archives_space_parent_id) { archives_space_id + "-no" }
			it 'returns false' do
				expect(result).to be false		
			end
		end
	end

	describe '#as_json' do
		context "without :include values" do
			it "does not include #metadata, #items, or context" do
				expect(iiif_collection).not_to receive(:items)
				expect(iiif_collection).not_to receive(:metadata)
				actual = iiif_collection.as_json
				expect(actual['@context']).to be_blank
				expect(actual['items']).to be_blank
				expect(actual['metadata']).to be_blank
			end
		end
	end
end