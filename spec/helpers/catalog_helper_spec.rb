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
  describe '#short_title' do
    let(:long_title) { '0123456789abcdefghijklmnopqrstuvwxyz' }
    let(:short_title) { '0123456789abc' }
    let(:title_value) { nil }
    let(:document) { { 'title_ssm' => title_value } }
    let(:view_context) { Struct.new(:document_index_view_type).new(:index) }
    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:index_presenter) { Dcv::IndexPresenter.new(document, view_context, blacklight_config) }
    before do
      allow(index_presenter).to receive(:heading).and_return(title_value)
      allow(helper).to receive(:index_presenter).and_return(index_presenter)
    end
    subject { helper.short_title(document) }
    context "a short title" do
      let(:title_value) { short_title }
      it { is_expected.to eql(short_title) }
    end
    context "a long title" do
      let(:title_value) { long_title }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end
    context "a long title in an array" do
      let(:title_value) { [long_title] }
      it { is_expected.to eql('0123456789abcdefghijklmnopq...') }
    end
    context "no title" do
      let(:document) { { 'some_field' => 'some_value' } }
      it { is_expected.to be_nil }
    end
  end

  describe '#total_dcv_object_count' do
    let (:solr_response) {
      {
        "response" => {
          "numFound" => 12345,
          "start" => 0,
          "docs" => []
        }
      }
    }
    let(:repository) { double(Blacklight::Solr::Repository) }
    let(:rsolr_connection) { double(RSolr::Client) }
    before do
      allow(Blacklight).to receive(:default_index).and_return(repository)
      allow(repository).to receive(:connection).and_return(rsolr_connection)
      allow(rsolr_connection).to receive(:send_and_receive).and_return(solr_response)
    end
    it do
      expect(helper.total_dcv_object_count('total_dcv_asset_count', "active_fedora_model_ssi:GenericResource")).to eq(12345)
    end
  end

  describe '#rounded_down_and_formatted_dcv_asset_count' do
    it do
      allow(helper).to receive(:total_dcv_object_count).and_return(12345)
      expect(helper.rounded_down_and_formatted_dcv_asset_count).to eq('12,000')
    end
  end

  describe '#rounded_down_and_formatted_dcv_object_count' do
    it do
      allow(helper).to receive(:total_dcv_object_count).and_return(12345)
      expect(helper.rounded_down_and_formatted_dcv_object_count).to eq('12,000')
    end
  end

  describe '#iframe_url_for_document' do
    subject { helper.iframe_url_for_document(SolrDocument.new(document)) }
    context 'with an IA result' do
      let(:document) do
        {
          'lib_non_item_in_context_url_ssm' => ['https://archive.org/details/sluggo'],
        }
      end
      it { is_expected.to match(/sluggo\?ui=(full|embed)/) }
    end
    context 'with a non-IA result' do
      let(:document) do
        {
          'lib_non_item_in_context_url_ssm' => ['https://library.org/details/sluggo'],
        }
      end
      # until we configure routes in this helper config
      it { is_expected.to be_nil }
    end
  end
  describe "#has_synchronized_media?" do
    subject { helper.has_synchronized_media?(document) }
    let(:document) { SolrDocument.new("datastreams_ssim" => datastreams) }
    context "no synchronized streams" do
      let(:datastreams) { [] }
      it { is_expected.to be false }
    end
    context "all synchronized streams" do
      let(:datastreams) { ['synchronized_transcript','chapters'] }
      it { is_expected.to be true }
    end
    context "synchronized captions streams" do
      let(:datastreams) { ['synchronized_transcript'] }
      it { is_expected.to be true }
    end
    context "synchronized chapters streams" do
      let(:datastreams) { ['chapters'] }
      it { is_expected.to be true }
    end
  end
  describe '#can_download?' do
    let(:site_slug) { 'siteSlug' }
    let(:subsite) { Site.new(slug: site_slug) }
    before do
      allow(controller).to receive(:load_subsite).and_return(subsite)
    end
    context "site displays original download links" do
      before do
        subsite.search_configuration.display_options.show_original_file_download = true
        expect(helper).to receive(:can?).and_return(allowed)
      end
      context "and permissions permit" do
        let(:allowed) { true }
        it { expect(helper.can_download?(SolrDocument.new)).to be true }
      end
      context "and permissions prohibit" do
        let(:allowed) { false }
        it { expect(helper.can_download?(SolrDocument.new)).to be false }
      end
    end
    context "site does not displays original download links" do
      before do
        subsite.search_configuration.display_options.show_original_file_download = false
      end
      it { expect(helper.can_download?(SolrDocument.new)).to be false }
    end
  end
end
