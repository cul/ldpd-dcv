require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource, type: :unit do
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
			let(:adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora(active_fedora_object) }
			let(:legacy_object) { GenericResource.allocate.init_with_object(rubydora_object) }
			let(:schema_image_uri) { legacy_object.get_singular_rel(:schema_image) }
			let(:schema_image_pid) { schema_image_uri ? schema_image_uri.split('/').last : nil }
			let(:schema_image_stub) do
				obj = double('ActiveFedora::Base')
				allow(obj).to receive(:pid).and_return(schema_image_pid)
				obj
			end
			before do
				allow(ActiveFedora::Base).to receive(:find).with(schema_image_pid).and_return(schema_image_stub)
			end
			it "produces comparable solr documents to the legacy indexing behavior" do
				expected = legacy_object.to_solr.delete_if { |k,v| v.blank? }
				actual = adapter.to_solr.delete_if { |k,v| v.blank? }
				expected_profile = expected.delete('object_profile_ssm')
				actual_profile = actual.delete('object_profile_ssm')
				expect(actual_profile).to eql(expected_profile)
				# legacy class has a strange text duplication
				expected_text = expected.delete('all_text_teim')
				actual_text = actual.delete('all_text_teim')
				expect(actual_text.uniq).to eql(expected_text.uniq)
				# legacy class does not wrap doi value in array
				expect(actual.delete('ezid_doi_ssim')).to eql([expected.delete('ezid_doi_ssim')])
				expect(actual).to eql(expected)
			end
			context "has zooming ds" do
				before do
					expect(adapter).to receive(:zooming_dsid).and_return("content")
				end
				it "produces a solr doc" do
					expect(adapter.to_solr['rft_id_ss']).to be_present
				end
			end
		end
	end
end