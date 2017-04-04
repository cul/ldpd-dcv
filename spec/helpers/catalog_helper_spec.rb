require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::CdnHelper. For example:
#
# describe CatalogHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe CatalogHelper, :type => :helper do
  before do
    allow(helper).to receive(:document_show_link_field).and_return(document_show_link_field)
  end
  let(:document) do
    {
      'title_short' => '0123456789abc',
      'title_long' => '0123456789abcdefghijklmnopqrstuvwxyz',
      'title_long_array' => ['0123456789abcdefghijklmnopqrstuvwxyz']
    }
  end
  describe '#short_title' do
    subject { helper.short_title(document) }
    context "a short title" do
      let(:document_show_link_field) { 'title_short' }
      it { is_expected.to eql('0123456789abc') }
    end
    context "a long title" do
      let(:document_show_link_field) { 'title_long' }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end
    context "a long title in an array" do
      let(:document_show_link_field) { 'title_long_array' }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end
    context "no title" do
      let(:document_show_link_field) { 'title_absent' }
      it { is_expected.to be_nil }
    end
  end
  describe '#url_for_document' do
    let(:slug) { 'sluggo' }
    let(:document_show_link_field) { 'title_short' }
    subject { helper.url_for_document(SolrDocument.new(document)) }
    context 'with a site result' do
      let(:document) do
        {
          'title_short' => '0123456789abc',
          'title_long' => '0123456789abcdefghijklmnopqrstuvwxyz',
          'title_long_array' => ['0123456789abcdefghijklmnopqrstuvwxyz'],
          'dc_type_ssm' => ['Publish Target'],
          'slug_ssim' => [slug]
        }
      end
      it { is_expected.to eql('/sites/' + slug) }
    end
    context 'with a non-site result' do
      let(:document) do
        {
          'title_short' => '0123456789abc',
          'title_long' => '0123456789abcdefghijklmnopqrstuvwxyz',
          'title_long_array' => ['0123456789abcdefghijklmnopqrstuvwxyz'],
          'dc_type_ssm' => ['Unpublish Target'],
          'slug_ssim' => [slug]
        }
      end
      # until we configure routes in this helper config
      it { is_expected.to be_a SolrDocument }
    end
  end
end
