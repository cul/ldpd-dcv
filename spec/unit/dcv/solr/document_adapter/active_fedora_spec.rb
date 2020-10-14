require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ActiveFedora, type: :unit do
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
		describe '#matches_any_cmodel?' do
			let(:adapter) { described_class.new(active_fedora_object) }
			let(:is_model) { "info:fedora/ldpd:Concept" }
			let(:not_model) { "info:fedora/ldpd:GenericResource" }
			it "returns true when any model is present" do
				expect(adapter.matches_any_cmodel?([not_model, is_model])).to be true
			end
			it "returns false when no models are present" do
				expect(adapter.matches_any_cmodel?([not_model])).to be false
			end
			it "returns false when no models queried" do
				expect(adapter.matches_any_cmodel?([])).to be false
			end
		end
		describe '#get_singular_relationship_value' do
			let(:adapter) { described_class.new(active_fedora_object) }
			let(:slug) { 'sites' }
			it "returns the first value" do
				expect(adapter.get_singular_relationship_value(:slug)).to eql(slug)
			end
		end
		describe '#to_solr' do
			let(:adapter) { described_class.new(active_fedora_object) }
			let(:schema_image_pid) { legacy_object.get_singular_rel(:schema_image).split('/').last }
			let(:schema_image_stub) do
				obj = double('ActiveFedora::Base')
				allow(obj).to receive(:pid).and_return(schema_image_pid)
				obj
			end
			before do
				allow(ActiveFedora::Base).to receive(:find).with(schema_image_pid).and_return(schema_image_stub)
			end
			context "has descMetadata" do
				let(:fedora_pid) { 'test:c_agg' }
				let(:legacy_object) { ContentAggregator.allocate.init_with_object(rubydora_object) }
				it "sets descriptor to mods" do
					expect(adapter.to_solr['descriptor_ssi']).to eql(["mods"])
				end
			end
			context "no descMetadata" do
				let(:fedora_pid) { 'donotuse:internal' }
				let(:legacy_object) { Concept.allocate.init_with_object(rubydora_object) }
				it "sets descriptor to mods" do
					expect(adapter.to_solr['descriptor_ssi']).to eql(["dublin core"])
				end
			end
		end
	end
end