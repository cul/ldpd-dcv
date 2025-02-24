require 'rails_helper'
describe Iiif::Manifest do
	let(:fedora_pid) { 'test:c_agg' }
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
	let(:active_fedora_object) do
		::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
	end
	let(:representative_resource) do
		gr_pid = 'test:gr'
		gr_foxml = fixture("foxml/#{gr_pid.sub(':','_')}.xml").read
		gr_repo = Rubydora::Repository.new({}, SingleObjectFcrApi.new(gr_foxml))
		gr_obj = ActiveFedora::DigitalObject.new(gr_pid, gr_repo)
		::ActiveFedora::Base.allocate.init_with_object(gr_obj)
	end
	let(:solr_adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora.new(active_fedora_object) }
	let(:manifest_document) { SolrDocument.new(solr_adapter.to_solr) }
	let(:ability_helper) do
		TestAbilityHelper.new
	end
	let(:route_helper) do
		TestRouteHelper.new(view_context: view_context)
	end
	let(:view_context) { double(ActionView::Context) }
	let(:children_service) { instance_double(Dcv::Solr::ChildrenAdapter, from_all_structure_proxies: child_documents) }
	let(:child_documents) { [] }
	let(:manifest_id) do
		registrant, doi = manifest_document.doi_identifier.split('/')
		route_helper.iiif_manifest_url(manifest_registrant: registrant, manifest_doi: doi)
	end
	let(:iiif_manifest) { described_class.new(id: manifest_id, solr_document: manifest_document, children_service: children_service, route_helper: route_helper, ability_helper: ability_helper) }
	before do
		allow(solr_adapter).to receive(:get_representative_generic_resource).and_return(representative_resource)
	end
	describe '#label' do
		let(:actual) { iiif_manifest.label }
		it "sets an array of values" do
			expect(actual[:en]).to be_a Array
			expect(actual[:en]).to include "With William Burroughs: a report from the bunker: Burroughs comes across a variety of the yage vine in the jungle..., p. 113, image"
		end
	end
	describe '#behavior' do
		let(:blacklight_config) { Blacklight::Configuration.new }
		let(:child_document_attrs) do
			[
				{
					id: 'cul:1234567',
					ezid_doi_ssim: ['doi:10.123/4567'],
					title_display_ssm: ['Child Document 1']
				},
				{
					id: 'cul:2345678',
					ezid_doi_ssim: ['doi:10.123/5678'],
					title_display_ssm: ['Child Document 2']
				},
				{
					id: 'cul:3456789',
					ezid_doi_ssim: ['doi:10.123/6789'],
					title_display_ssm: ['Child Document 3']
				}
			]
		end
		let(:child_documents) { child_document_attrs.map { |child_attrs| SolrDocument.new(child_attrs)} }

		before do
			allow(ability_helper).to receive(:can?).and_return(true)
			allow(view_context).to receive(:blacklight_config).and_return(blacklight_config)
		end

		context 'item is structured' do
			before do
				manifest_document['datastreams_ssim'] << 'structMetadata'
			end
			it 'defaults to individuals' do
				expect(children_service).to receive(:from_all_structure_proxies).and_return(child_documents)
				actual = iiif_manifest.as_json(include: [:metadata])
				expect(actual['behavior']).to eql ['individuals']
			end
		end
		it 'defaults to unordered' do
			expect(children_service).to receive(:from_unordered_membership).and_return(child_documents)
			actual = iiif_manifest.as_json(include: [:metadata])
			expect(actual['behavior']).to eql ['unordered']
		end
	end
	describe '#items' do
		let(:child_document) do
			SolrDocument.new({
				id: 'cul:1234567',
				ezid_doi_ssim: ['doi:10.123/45678'],
				title_display_ssm: ['Child Document']
			})
		end
		let(:child_documents) { [child_document] }

		before do
			allow(ability_helper).to receive(:can?).and_return(true)
		end

		it 'delegates to children_service for child list' do
			expect(children_service).to receive(:from_unordered_membership).and_return(child_documents)
			expect(iiif_manifest.items.first&.dig('label', 'en')).to eql ['Child Document']
		end
	end
	describe '#as_json' do
		context "without :include values" do
			it "does not include #metadata, #items, or context" do
				expect(iiif_manifest).not_to receive(:items)
				expect(iiif_manifest).not_to receive(:metadata)
				actual = iiif_manifest.as_json
				expect(actual['@context']).to be_blank
				expect(actual['items']).to be_blank
				expect(actual['metadata']).to be_blank
			end
		end
	end
end