require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ActiveFedora::Concept, type: :unit do
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:object_profile) { fixture("foxml/object_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:datastreams_response) { fixture("foxml/datastream_profiles/#{fedora_pid.sub(':','_')}.xml").read }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:adapter) { described_class.new(nil) }
	it { expect(adapter).to respond_to :to_solr }
	context "with fedora data" do
		let(:fedora_pid) { 'donotuse:public' }
		let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
		let(:active_fedora_object) do
			::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
		end
		describe '#to_solr' do
			let(:fedora_pid) { 'donotuse:internal' }
			let(:adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora(active_fedora_object) }
			let(:legacy_object) { ::ActiveFedora::Base.allocate.init_with_object(rubydora_object) }
			let(:legacy_cmodel) { 'info:fedora/ldpd:Concept' }
			let(:dc_fields) { Dcv::Solr::DocumentAdapter::DcXml.new(legacy_object.datastreams['DC'].content).to_solr }
			let(:schema_image_uri) { adapter.get_singular_relationship_value(:schema_image) }
			let(:schema_image_pid) { schema_image_uri ? schema_image_uri.split('/').last : nil }
			let(:schema_image_stub) do
				obj = double('ActiveFedora::Base')
				allow(obj).to receive(:pid).and_return(schema_image_pid)
				obj
			end
			let(:description_value) { Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(adapter.description).encode(Encoding::UTF_8) }
			before do
				allow(ActiveFedora::Base).to receive(:find).with(schema_image_pid).and_return(schema_image_stub)
				legacy_object.add_relationship(:has_model, legacy_cmodel)
			end
			it "produces comparable solr documents to the legacy indexing behavior" do
				expected = legacy_object.to_solr
				actual = adapter.to_solr
				expected_profile = expected.delete('object_profile_ssm')
				actual_profile = actual.delete('object_profile_ssm')
				expect(actual_profile).to eql(expected_profile)
				# ActiveFedora::Base will not set specialized class
				expected.delete('active_fedora_model_ssi')
				expect(actual.delete('active_fedora_model_ssi')).to eql 'Concept'
				# all_text_teim would have been overridden by mods
				dc_fields.delete('all_text_teim')
				expect(actual.slice(*dc_fields.keys)).to eql(dc_fields)
				actual.delete_if { |k, v| dc_fields.include?(k) }
				expect(actual.delete('title_si')).to eql(dc_fields['dc_title_ssm'].first)
				expect(actual.delete('title_display_ssm')).to eql(dc_fields['dc_title_ssm'])
				# check normalized contributor relationship
				expect(actual.delete('contributor_first_si')).to eql Array(actual["contributor_ssim"])&.first
				# check concept specific indexing
				expect(actual.delete('format_ssi')).to eql(["concept"])
				expect(actual.delete('cul_number_of_members_isi')).to eql(0)
				expect(actual.delete('representative_generic_resource_pid_ssi')).to eql("cul:1c59zw3rf4")
				expect(actual.delete('index_type_label_ssi')).to eql(["EMPTY"])
				expect(actual.delete('description_text_ssm')).to eql description_value
				# delete fields verified in base class spec
				actual.delete('cul_number_of_members_isi')
				actual.delete('datastreams_ssim')
				actual.delete('descriptor_ssi')
				actual.delete('fedora_pid_uri_ssi')
				actual.delete('index_type_label_ssi')
				# do not compare types of blank value that will not impact index
				actual.delete_if { |k,v| v.blank? }
				expected.delete_if { |k,v| v.blank? }
				# at this point should be basic legacy ActiveFedora fields and rel indexing
				expect(actual).to eql(expected)
			end
		end
	end
end