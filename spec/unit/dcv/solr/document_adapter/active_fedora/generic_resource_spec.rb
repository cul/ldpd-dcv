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
			let(:legacy_object) { ::ActiveFedora::Base.allocate.init_with_object(rubydora_object) }
			let(:legacy_cmodel) { 'info:fedora/ldpd:GenericResource' }
			let(:mods_fields) { Dcv::Solr::DocumentAdapter::ModsXml.new(legacy_object.datastreams['descMetadata'].content).to_solr.delete_if { |k,v| v.blank? } }
			let(:dc_fields) { Dcv::Solr::DocumentAdapter::DcXml.new(legacy_object.datastreams['DC'].content).to_solr.delete_if { |k,v| v.blank? } }
			let(:xacml_fields) { Dcv::Solr::DocumentAdapter::XacmlXml.new(legacy_object.datastreams['accessControlMetadata'].content).to_solr.delete_if { |k,v| v.blank? } }
			let(:rels_int_fields) { adapter.rels_int.to_solr({}) }
			let(:schema_image_uri) { adapter.get_singular_relationship_value(:schema_image) }
			let(:schema_image_pid) { schema_image_uri ? schema_image_uri.split('/').last : nil }
			let(:schema_image_stub) do
				obj = double('ActiveFedora::Base')
				allow(obj).to receive(:pid).and_return(schema_image_pid)
				obj
			end
			let(:mock_iiif_data) { instance_double(Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource::IiifData) }

			before do
				adapter.instance_variable_set(:@iiif_adapter, mock_iiif_data)
				allow(mock_iiif_data).to receive(:to_solr) do |arg|
					arg
				end
				allow(ActiveFedora::Base).to receive(:find).with(schema_image_pid).and_return(schema_image_stub)
				legacy_object.add_relationship(:has_model, legacy_cmodel)
			end
			it "produces comparable solr documents to the legacy indexing behavior" do
				# some values are literal false, so can't use blank? alone to compact
				expected = legacy_object.to_solr.delete_if { |k,v| v != false && v&.blank? }
				actual = adapter.to_solr.delete_if { |k,v| v != false && v&.blank? }
				expected_profile = expected.delete('object_profile_ssm')
				actual_profile = actual.delete('object_profile_ssm')
				expect(actual_profile).to eql(expected_profile)
				# ActiveFedora::Base will not set specialized class
				expected.delete('active_fedora_model_ssi')
				expect(actual.delete('active_fedora_model_ssi')).to eql 'GenericResource'
				# legacy class does not wrap doi value in array
				expect(actual.delete('ezid_doi_ssim')).to eql([expected.delete('ezid_doi_ssim')])
				# base class uniq's all_text_teim
				mods_fields['all_text_teim'].uniq!
				expect(actual.slice(*mods_fields.keys)).to eql(mods_fields)
				actual.delete_if { |k, v| mods_fields.include?(k) }
				expect(actual.slice(*xacml_fields.keys)).to eql(xacml_fields)
				actual.delete_if { |k, v| xacml_fields.include?(k) }
				expect(actual.slice(*rels_int_fields.keys)).to eql(rels_int_fields)
				actual.delete_if { |k, v| rels_int_fields.include?(k) }
				# all_text_teim would have been overridden by mods
				dc_fields.delete('all_text_teim')
				expect(actual.slice(*dc_fields.keys)).to eql(dc_fields)
				actual.delete_if { |k, v| dc_fields.include?(k) }
				# check generic_resource specific indexing
				expect(actual.delete('format_ssi')).to eql(["resource"])
				expect(actual.delete('structured_bsi')).to eql(false)
				expect(actual.delete('index_type_label_ssi')).to eql(["FILE ASSET"])
				expect(actual.delete('representative_generic_resource_pid_ssi')).to eql(fedora_pid)
				expect(actual.delete('original_name_tesim')).to eql(adapter.original_name_text)
				expect(actual.delete('fulltext_tesim')).to eql(adapter.fulltext_values(["Image of Pulse Transformer Circuit"]))
				expect(actual.delete('extent_ssim')).to eql([legacy_object.datastreams["content"].dsSize.to_i])				
				# delete fields verified in base class spec
				actual.delete('datastreams_ssim')
				actual.delete('descriptor_ssi')
				actual.delete('fedora_pid_uri_ssi')
				# do not compare types of blank value that will not impact index
				actual.delete_if { |k,v| v.blank? }
				expected.delete_if { |k,v| v.blank? }
				expect(actual).to eql(expected)
			end
		end
	end
end