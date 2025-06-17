require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::CdnHelper. For example:
#
# describe Dcv::CdnHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe Dcv::CdnHelper, :type => :helper do
  let(:test_url) { 'http://test.org' }
  let(:test_id) { 'test:1' }
  let(:image_id) { 'image:1' }
  before do
    @original_config = DCV_CONFIG['cdn_urls']
    DCV_CONFIG['cdn_urls'] = [test_url]
  end
  subject { helper.thumbnail_url(SolrDocument.new(document)) }
  context "document has a schema_image array" do
    let(:document) { {'id' => test_id, 'schema_image_ssim' => [image_id]} }
    it { is_expected.to eql("#{test_url}/iiif/2/featured/#{image_id}/full/!256,256/0/default.jpg")}
  end
  context "document has a schema_image" do
    let(:document) { {'id' => test_id, 'schema_image_ssim' => image_id} }
    it { is_expected.to eql("#{test_url}/iiif/2/featured/#{image_id}/full/!256,256/0/default.jpg")}
  end
  context "document has no schema_image" do
    let(:document) { {'id' => test_id} }
    it { is_expected.to eql("#{test_url}/iiif/2/featured/#{test_id}/full/!256,256/0/default.jpg")}
  end
end
