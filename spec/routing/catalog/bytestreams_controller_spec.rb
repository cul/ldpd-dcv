require 'rails_helper'

describe BytestreamsController, :type => :routing do
  describe "routing" do
    let(:well_known_doi) { "10.123/1a2b-3c4d5e" }
    let(:well_known_dsid) { "content" }
    let(:well_known_pid) { "cul:12345" }
    it "routes to #index" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams").to route_to(controller: "bytestreams", action:"index", catalog_id: well_known_pid)
    end
    it "routes pid ids with dsid to show action" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams/#{well_known_dsid}").to route_to(controller: "bytestreams", action:"show", catalog_id: well_known_pid, id: well_known_dsid)
    end
    it "routes to content action" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams/#{well_known_dsid}/content").to route_to(controller: "bytestreams", action:"content", catalog_id: well_known_pid, bytestream_id: well_known_dsid)
    end
    it "routes to probe action" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams/#{well_known_dsid}/probe").to route_to(controller: "bytestreams", action:"probe", catalog_id: well_known_pid, bytestream_id: well_known_dsid)
    end
    it "routes to access action" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams/#{well_known_dsid}/access").to route_to(controller: "bytestreams", action:"access", catalog_id: well_known_pid, bytestream_id: well_known_dsid)
    end
    it "routes to token action" do
      expect(:get => "/catalog/#{well_known_pid}/bytestreams/#{well_known_dsid}/token").to route_to(controller: "bytestreams", action:"token", catalog_id: well_known_pid, bytestream_id: well_known_dsid)
    end
  end
end
