require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ActiveFedora::Collection, type: :unit do
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:object_profile) { fixture("foxml/object_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:datastreams_response) { fixture("foxml/datastream_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:adapter) { described_class.new(nil) }
	it { expect(adapter).to respond_to :to_solr }
	context "with fedora data" do
		let(:fedora_pid) { 'test:collection' }
		let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
		let(:active_fedora_object) do
			::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
		end
		let(:adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora(active_fedora_object) }
		describe '#to_solr' do
			let(:legacy_object) { Collection.allocate.init_with_object(rubydora_object) }
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
				expected = legacy_object.to_solr
				actual = adapter.to_solr
				expected_profile = expected.delete('object_profile_ssm')
				actual_profile = actual.delete('object_profile_ssm')
				expect(actual_profile).to eql(expected_profile)
				# legacy class does not set structured flag!
				expect(actual.delete('structured_bsi')).to be true
				# legacy class does not wrap doi value in array
				expect(actual.delete('ezid_doi_ssim')).to eql([expected.delete('ezid_doi_ssim')])
				# do not compare types of blank value that will not imapct index
				actual.delete_if { |k,v| v.blank? }
				expected.delete_if { |k,v| v.blank? }
				expect(actual).to eql(expected)
			end
		end
		describe '#proxies' do
			it "produces proxy objects that respod to :to_solr from structMetadata" do
				expect(adapter.proxies.length).to be 7
				expect(adapter.proxies.first).to respond_to(:to_solr)
			end
		end
	end
end