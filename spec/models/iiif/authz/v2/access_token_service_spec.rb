require 'rails_helper'

describe Iiif::Authz::V2::AccessTokenService do
  subject(:access_token_service) {
    described_class.new(
      canvas, route_helper: routes, format: format, profile: profile
    )
  }
  let(:canvas) { instance_double(Iiif::Canvas) }
  let(:expected_id) { 'expected_id' }
  let(:format) { nil }
  let(:routes) { instance_double(ApplicationController) }
  let(:solr_document_id) { 'solr_document_id' }

  before do
    allow(canvas).to receive(:solr_document).and_return(SolrDocument.new({id: solr_document_id}))
    allow(routes).to receive(:bytestream_token_url).with(id_params).and_return(expected_id)
  end

  context 'profile is external' do
    let(:profile) { 'external' }
    let(:id_params) { {catalog_id: solr_document_id, bytestream_id: 'content', profile: profile} }

    it "creates a hashable token service with the expected id" do
      expect(access_token_service.to_h['id']).to be expected_id
    end
  end

  context 'profile is kiosk' do
    let(:profile) { 'kiosk' }
    let(:id_params) { {catalog_id: solr_document_id, bytestream_id: 'content', profile: profile} }

    it "creates a hashable token service with the expected id" do
      expect(access_token_service.to_h['id']).to be expected_id
    end
  end

  context 'profile is active' do
    let(:profile) { 'active' }
    # active profile should not include additional query params to distinguish it
    let(:id_params) { {catalog_id: solr_document_id, bytestream_id: 'content'} }

    it "creates a hashable token service with the expected id" do
      expect(access_token_service.to_h['id']).to be expected_id
    end
  end
end
