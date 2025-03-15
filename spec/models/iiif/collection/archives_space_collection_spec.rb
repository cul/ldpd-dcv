require 'rails_helper'
describe Iiif::Collection::ArchivesSpaceCollection do
	let(:archives_space_id) { '0123456789abcdeffedcba987654321' }
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

	describe '#archives_space_id' do
		it 'parses the aspace idenitifer from the id URI' do
			expect(iiif_collection.archives_space_id).to eql(archives_space_id)
		end		
	end

	describe '#label' do
		let(:actual) { iiif_collection.label }
		pending "sets an array of values" do
			expect(actual[:en]).to be_a Array
			expect(actual[:en]).not_to be_empty
		end
	end

	describe '#items' do
		let(:item) { instance_double(SolrDocument, doi_identifier: '10.123/abcdef', :[] => nil) }
		pending 'delegates to children_service for structured list' do
			expect(children_service).to receive(:from_aspace_parent).with(archives_space_id).and_return([item])
			expect(iiif_collection.items).not_to be_empty
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