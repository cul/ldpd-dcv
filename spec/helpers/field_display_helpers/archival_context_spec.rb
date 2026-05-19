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
  let(:xml_src) { fixture(File.join("mods", "mods-archival-context.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { Dcv::Solr::DocumentAdapter::ModsXml.new(ng_xml) }
  let(:solr_data) { adapter.to_solr }
  let(:field_config) { instance_double(Blacklight::Configuration::Field) }
  include_context "a solr document"

  describe "#display_collection_with_links" do
    let(:value) { 'Carnegie Corporation of New York Records' }
    let(:solr_data) { adapter.to_solr.merge({ id: document_id }) }
    subject(:display) { helper.display_collection_with_links(document: solr_document, value: value).first }

    context 'collection has a bib id' do
      context 'and it has a repo code and archival context' do
        it 'links to the finding aid' do
          expect(display).to match(/finding/)
        end
      end

      context 'with an instance prefix' do
        let(:xml_src) { fixture(File.join("mods", "mods-aspace-ids.xml")) }
        let(:value) { 'Italian Jewish Community Regulations' }

        it 'links to the finding aid' do
          expect(display).to match(/finding/)
        end
      end

      context 'and it has further archival context but no repo code' do
        before do
          # delete the repo code data and the titles used to try to backfill it
          solr_data.delete("lib_repo_code_ssim")
          solr_data.delete("lib_repo_full_ssim")
          solr_data.delete("lib_repo_short_ssim")
        end

        it 'links to the finding aid' do
          expect(display).to match(/finding/)
        end
      end

      context 'and it has no further archival context' do
        before do
          json = JSON.load(solr_data["archival_context_json_ss"])
          json.first["dc:coverage"] = []
          solr_data["archival_context_json_ss"] = JSON.generate(json)
        end

        it 'links to clio' do
          expect(display).to match(/clio/)
        end
      end
    end

    context 'collection has no bib id' do
      before do
        json = JSON.load(solr_data["archival_context_json_ss"])
        json.first["dc:bibliographicCitation"]["@id"] = 'https://server.columbia.edu/catalog'
        solr_data["archival_context_json_ss"] = JSON.generate(json)
      end

      it 'links when the collection has a bib id' do
        expect(display).to eql value
      end
    end
  end

  # this helper produces a composed label of collection and archival context with no links.
  # it is used in index views.
  describe "#display_composite_archival_context" do
    let(:xml_src) { fixture(File.join("mods", "mods-aspace-ids.xml")) }
    let(:solr_data) { adapter.to_solr }
    let(:collection_value) { ["Italian Jewish Community Regulations"] }
    let(:expected) { "Italian Jewish Community Regulations. Series I: Ferrara (Italy). Subseries I.D Noise Regulations" }

    it 'builds values without modifying the solr document over multiple calls' do
      args = {document: solr_document, value: collection_value, shelf_locator: false}
      # see also DLC-1194
      expect(helper.display_composite_archival_context(**args).first).to eql expected
      expect(helper.display_composite_archival_context(**args).first).to eql expected
      expect(helper.display_composite_archival_context(**args).first).to eql expected
    end
  end
end