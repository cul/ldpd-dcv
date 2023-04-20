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
    it 'links when the collection has a bib id' do
      expect(helper.display_collection_with_links(document: solr_document, value: value).first).to match(/href/)
    end
    context 'collection has no bib id' do
      before do
        json["dc:bibliographicCitation"]["@id"] = 'https://clio.columbia.edu/catalog'
      end
      it 'links when the collection has a bib id' do
        expect(helper.display_collection_with_links(document: solr_document, value: value).first).to eql value
      end
    end
  end
end