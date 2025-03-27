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
		let(:actual) { iiif_collection.label }
  
		it "sets an array of values" do
	  		expect(actual[:en]).to be_a Array
	  		expect(actual[:en]).to include("Italian Jewish Community Regulations")
		end
		context 'has an item in scope' do
			let(:json_src) { fixture('json/archival_context.json').read }
			let(:json) { JSON.load(json_src) }
			let(:field_config) { instance_double(Blacklight::Configuration::Field) }
			let(:value) { 'Carnegie Corporation of New York Records' }
			let(:solr_data) {
				{
					id: document_id, archival_context_json_ss: JSON.generate([json]), lib_repo_code_ssim: 'nnc'
				}
			}
			include_context "a solr document"
			let(:collection_item) { SolrDocument.new(solr_document._source.merge(ezid_doi_ssim: [item_doi])) }


			it 'delegates to children_service for structured list' do
				expect(iiif_collection.items).not_to be_empty
				expect(iiif_collection.items[0].instance_variable_get(:@part_of)).to eq(collection_id)
				expect(iiif_collection.items[0].instance_variable_get(:@id)).to eq(item_manifest_id)
			end
		end
  	end

	describe '#items' do
		it 'delegates to children_service for structured list' do
			expect(children_service).to receive(:from_aspace_parent).with(archives_space_id).and_return([collection_item])
			expect(iiif_collection.items).not_to be_empty
			expect(iiif_collection.items[0].instance_variable_get(:@part_of)).to eq(collection_id)
			expect(iiif_collection.items[0].instance_variable_get(:@id)).to eq(item_manifest_id)
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