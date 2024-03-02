require 'rails_helper'

describe BytestreamsController, :type => :routing do
  let(:catalog_id) { "test:gr" }
  let(:bytestream_id) { "content" }
  describe "routing" do
    it "routes to #content_options" do
      expect(options: "/catalog/#{catalog_id}/bytestreams/#{bytestream_id}/content").to route_to(
        controller: "bytestreams", action:"content_options", catalog_id: catalog_id, bytestream_id: bytestream_id
      )
    end
    it "routes to #content_head" do
      expect(head: "/catalog/#{catalog_id}/bytestreams/#{bytestream_id}/content").to route_to(
        controller: "bytestreams", action:"content_head", catalog_id: catalog_id, bytestream_id: bytestream_id
      )
    end
    it "routes to #content" do
      expect(get: "/catalog/#{catalog_id}/bytestreams/#{bytestream_id}/content").to route_to(
        controller: "bytestreams", action:"content", catalog_id: catalog_id, bytestream_id: bytestream_id
      )
    end
  end
  describe "url_helpers" do
    it do
      expect(bytestream_content_path(catalog_id: catalog_id, bytestream_id: bytestream_id)).to eql("/catalog/#{catalog_id}/bytestreams/#{bytestream_id}/content")
    end
  end
end
