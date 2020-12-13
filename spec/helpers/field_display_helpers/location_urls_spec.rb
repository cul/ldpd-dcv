require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the FieldDisplayHelpers::LocationUrls. For example:
#
# describe FieldDisplayHelpers::LocationUrls do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe FieldDisplayHelpers::LocationUrls, :type => :helper do
  let(:field_config) { instance_double(Blacklight::Configuration::Field) }
  let(:display_label) { 'External Example Related Resource' }
  let(:related_url) { 'https://www.example.org/relatedResource' }
  include_context "a solr document"
  let(:solr_data) {
    {
      id: document_id, location_url_json_ss: JSON.dump(url_array)
    }
   }
  describe '#has_related_urls?' do
    subject { helper.has_related_urls?(field_config, solr_document) }
    context 'document has no related urls' do
      let(:url_array) { [] }
      it { is_expected.to be false }
    end
    context 'document has related urls' do
      context 'that are not usage primary' do
        let(:url_array) {
          [
            {
              displayLabel: display_label,
              url: related_url
            }
          ]
        }
        it { is_expected.to be true }
      end
      context 'that are all usage primary' do
        let(:url_array) {
          [
            {
              displayLabel: display_label,
              url: related_url,
              usage: "primary display"
            }
          ]
        }
        it { is_expected.to be false }
      end
    end
  end
  describe '#display_related_urls' do
    subject { helper.display_related_urls(document: solr_document) }
    context 'document has no related urls' do
      let(:url_array) { [] }
      it { is_expected.to be_empty }
    end
    context 'document has related urls' do
      context 'that are not usage primary' do
        let(:url_array) {
          [
            {
              displayLabel: display_label,
              url: related_url
            }
          ]
        }
        it { is_expected.to include "<a href=\"https://www.example.org/relatedResource\"><span class=\"glyphicon glyphicon-paperclip\"></span> External Example Related Resource</a>" }
      end
      context 'that are all usage primary' do
        let(:url_array) {
          [
            {
              displayLabel: display_label,
              url: related_url,
              usage: "primary display"
            }
          ]
        }
        it { is_expected.to be_empty }
      end
    end
  end
end