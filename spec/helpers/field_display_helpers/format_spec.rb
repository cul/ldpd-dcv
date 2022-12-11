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

describe FieldDisplayHelpers::Format, :type => :helper do
  let(:field_config) { instance_double(Blacklight::Configuration::Field) }
  let(:display_label) { 'External Example Related Resource' }
  include_context "a solr document"
  context "document parameter has a image dc_type_ssm and text format value in another field" do
    let(:solr_data) {
      {
        id: document_id, dc_type_ssm: ['Image'], other_field: 'PageDescription'
      }
    }
    describe '#is_image_document?' do
      it do
        expect(helper.is_image_document?(solr_document)).to be true
        expect(helper.is_image_document?(solr_document, :other_field)).to be false
      end
    end
    describe '#is_text_document?' do
      it do
        expect(helper.is_text_document?(solr_document)).to be false
        expect(helper.is_text_document?(solr_document, :other_field)).to be true
      end
    end
  end
end