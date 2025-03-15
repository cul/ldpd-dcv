require 'rails_helper'
describe Iiif::Collection::ProxyCollection do
	let(:fedora_pid) { 'test:collection' }
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
	let(:active_fedora_object) do
		::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
	end
	let(:solr_adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora.new(active_fedora_object) }
	let(:collection_document) { SolrDocument.new(solr_adapter.to_solr) }
	let(:ability_helper) do
		TestAbilityHelper.new
	end
	let(:route_helper) do
		TestRouteHelper.new
	end
	let(:children_service) { instance_double(Dcv::Solr::ChildrenAdapter) }
	let(:collection_id) do
		registrant, doi = collection_document.doi_identifier.split('/')
		route_helper.iiif_proxy_collection_url(collection_registrant: registrant, collection_doi: doi)
	end
	let(:iiif_collection) { described_class.new(id: collection_id, solr_document: collection_document, children_service: children_service, ability_helper: ability_helper, route_helper: route_helper) }
	describe '#label' do
		let(:actual) { iiif_collection.label }
		it "sets an array of values" do
			expect(actual[:en]).to be_a Array
			expect(actual[:en]).to include "Uganda Office Archive"
		end
	end
	describe '#items' do
		let(:item) { instance_double(SolrDocument, doi_identifier: '10.123/abcdef', :[] => nil) }
		it 'delegates to children_service for structured list' do
			expect(children_service).to receive(:from_contained_structure_proxies).and_return([item])
			iiif_collection.items
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