require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Ifp::PartnerDataHelper. For example:
#
# describe Ifp::PartnerDataHelper do
#   describe "#onsite_only" do
#     let(:example_field) { 'field_ssim' }
#     let(:doc) { SolrDocument.new({ example_field => [] }) }
#     it "detects when restricted ifp is only publish target" do
#       expect(helper.onsite_only(document: doc, field: example_field).to be_false
#     end
#   end
# end

describe Ifp::PartnerDataHelper, :type => :helper do
  describe '#link_to_partner' do
    before do
      allow(controller).to receive(:restricted?).and_return(false)
    end
    it "links with options" do
      expect(helper.link_to_partner('brazil', id: 'some-id-value')).to include('id="some-id-value"')
    end
  end
end
