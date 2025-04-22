require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the FieldDisplayHelpers::Format. For example:
#
# describe FieldDisplayHelpers::Format do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe FieldDisplayHelpers::ArchivalContext, :type => :helper do
  let(:json_src) { fixture('json/archival_context.json').read }
  let(:json) { JSON.load(json_src) }
  let(:field_config) { instance_double(Blacklight::Configuration::Field) }
  include_context "a solr document"
  describe "#display_collection_with_links" do
    let(:value) { 'Carnegie Corporation of New York Records' }
    let(:solr_data) {
      {
        id: document_id, archival_context_json_ss: JSON.generate([json]), lib_repo_code_ssim: 'nnc'
      }
    }
    subject(:display) { helper.display_collection_with_links(document: solr_document, value: value).first }
    context 'collection has a bib id' do
      it 'links to the finding aid' do
        expect(display).to match(/finding/)
      end
      context 'collection has no further archival context' do
        before do
          json["dc:coverage"] = []
        end
        it 'links to clio' do
          expect(display).to match(/clio/)
        end
      end
    end
    context 'collection has no bib id' do
      before do
        json["dc:bibliographicCitation"]["@id"] = 'https://server.columbia.edu/catalog'
      end
      it 'links when the collection has a bib id' do
        expect(display).to eql value
      end
    end
  end
  describe "#display_composite_archival_context" do
    let(:xml_src) { fixture(File.join("mods", "mods-aspace-ids.xml")) }
    let(:ng_xml) { Nokogiri::XML(xml_src.read) }
    let(:adapter) { Dcv::Solr::DocumentAdapter::ModsXml.new(ng_xml) }
    let(:solr_data) { adapter.to_solr }
    let(:collection_value) { ["Italian Jewish Community Regulations"] }
    let(:expected) { "Italian Jewish Community Regulations. Series I: Ferrara (Italy). Subseries I.D Noise Regulations" }
    it 'builds values without modifying the solr document over multiple calls' do
      args = {document: solr_document, value: collection_value, shelf_locator: false}
      expect(helper.display_composite_archival_context(**args).first).to eql expected
      expect(helper.display_composite_archival_context(**args).first).to eql expected
      expect(helper.display_composite_archival_context(**args).first).to eql expected
    end
  end
end