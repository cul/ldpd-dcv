require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource::IiifData, type: :unit do
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:object_profile) { fixture("foxml/object_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:datastreams_response) { fixture("foxml/datastream_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:adapter) { described_class.new(nil) }
	it { expect(adapter).to respond_to :to_solr }
	context "with fedora data" do
		let(:fedora_pid) { 'test:gr' }
		let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
		let(:active_fedora_object) do
			::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
		end
		describe '#to_solr' do
			let(:fedora_pid) { 'test:gr' }
			let(:adapter) { described_class.new(active_fedora_object) }
			let(:legacy_cmodel) { 'info:fedora/ldpd:GenericResource' }
			let(:iiif_data) { { 'width' => 200, 'height' => 400 } }
			subject(:solr_doc) { adapter.to_solr }
			before do
				active_fedora_object.add_relationship(:has_model, legacy_cmodel)
			end

			it "fetches CDN IIIF data" do
				expect(adapter).to receive(:fetch_iiif_data).with(/test\:gr\/info\.json/).and_return(iiif_data)
				expect(solr_doc['image_width_isi']).to be 200
				expect(solr_doc['image_height_isi']).to be 400
			end
		end
	end
end