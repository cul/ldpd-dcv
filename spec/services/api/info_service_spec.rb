require "rails_helper"

RSpec.describe Api::InfoService do
  subject(:result) { described_class.new(item_id, asset_id).call }

  let(:item_id) { "item-123" }
  let(:asset_id) { "asset-456" }

  let(:item_document) do
    {
      "id" => "item-solr-id",
      "identifier_ssim" => [item_id],
      "title_display_ssm" => ["My 1901 Collection"],
      "primary_name_ssm" => ["Ann Author"],
      "origin_info_date_created_ssm" => ["1901"],
      "lib_collection_ssm" => ["Special Collections"],
      "physical_description_extent_ssm" => ["12 pages"]
    }
  end

  let(:asset_document) do
    {
      "id" => "asset-solr-id",
      "identifier_ssim" => [asset_id]
    }
  end

  before do
    allow_any_instance_of(described_class)
      .to receive(:search_documents)
      .and_return([item_document, asset_document])
  end

  describe "#call" do
    context "when both documents are found" do
      it "returns a successful result" do
        expect(result.success?).to be(true)
        expect(result.status).to eq(:ok)
      end

      it "returns formatted metadata" do
        expect(result.data).to eq(
          identifier: "item-solr-id",
          imageSourceUrl: "https://triclops.library.columbia.edu/iiif/2/standard/asset-solr-id/full/!1280,1280/0/default.jpg",
          title: "My 1901 Collection",
          author: "Ann Author",
          dateCreated: "1901",
          collection: "Special Collections",
          extent: "12 pages"
        )
      end

      it "does not include errors" do
        expect(result.error_message).to be_nil
        expect(result.error_code).to be_nil
      end
    end

    context "when the item document is missing" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_return([asset_document])
      end

      it "returns not found with the missing item identifier" do
        expect(result.success?).to be(false)
        expect(result.status).to eq(:not_found)
        expect(result.error_code).to eq("not_found")
        expect(result.error_message).to eq(
          "Solr document(s) not found for identifier(s): item_id=#{item_id}"
        )
      end
    end

    context "when the asset document is missing" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_return([item_document])
      end

      it "returns not found with the missing asset identifier" do
        expect(result.success?).to be(false)
        expect(result.status).to eq(:not_found)
        expect(result.error_code).to eq("not_found")
        expect(result.error_message).to eq(
          "Solr document(s) not found for identifier(s): asset_id=#{asset_id}"
        )
      end
    end

    context "when both documents are missing" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_return([])
      end

      it "returns all missing identifiers" do
        expect(result.success?).to be(false)
        expect(result.status).to eq(:not_found)
        expect(result.error_code).to eq("not_found")
        expect(result.error_message).to eq(
          "Solr document(s) not found for identifier(s): " \
          "item_id=#{item_id}, asset_id=#{asset_id}"
        )
      end
    end

    context "when metadata fields are missing" do
      let(:item_document) do
        {
          "id" => "item-solr-id",
          "identifier_ssim" => [item_id]
        }
      end

      it "returns null for missing metadata" do
        expect(result.data).to include(
          title: "null",
          author: "null",
          dateCreated: "null",
          collection: "null",
          extent: "null"
        )
      end
    end

    context "when Solr raises an HTTP error" do
    let(:solr_error) do 
        RSolr::Error::Http.new(
          { uri: URI("http://localhost:8983/solr") }, 
          { status: 503, body: "Solr unavailable" }
        )
      end

      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_raise(solr_error)
      end

      it "returns a failure result" do
        expect(result.success?).to be(false)
        expect(result.status).to eq(:service_unavailable)
        expect(result.error_code).to eq("solr_error")
        expect(result.error_message)
          .to include("Unable to query Solr")
      end
    end

    context "when duplicate item identifiers are returned" do
      let(:duplicate_item) do
        item_document.merge(
          "id" => "duplicate-item-id"
        )
      end

      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_return([item_document, duplicate_item, asset_document])
      end

      it "raises DuplicateIdentifierError" do
        expect do
          result
        end.to raise_error(
          Api::InfoService::DuplicateIdentifierError,
          item_id
        )
      end
    end

    context "when duplicate asset identifiers are returned" do
      let(:duplicate_asset) do
        asset_document.merge(
          "id" => "duplicate-asset-id"
        )
      end

      before do
        allow_any_instance_of(described_class)
          .to receive(:search_documents)
          .and_return([item_document, asset_document, duplicate_asset])
      end

      it "raises DuplicateIdentifierError" do
        expect do
          result
        end.to raise_error(
          Api::InfoService::DuplicateIdentifierError,
          asset_id
        )
      end
    end
  end
end
