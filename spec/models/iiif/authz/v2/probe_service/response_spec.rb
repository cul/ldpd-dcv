require 'rails_helper'

describe Iiif::Authz::V2::ProbeService::Response do
  subject(:probe_response) {
    _pr = described_class.new(
      document: solr_document,
      bytestream_id: 'content',
      ability_helper: controller,
      route_helper: controller,
      remote_ip: remote_ip,
      authorization: authorization_header
    )
    _pr.instance_variable_set(:@token_authorizer, token_authorizer)
    _pr
  }
  let(:authorization_header) { "Bearer token.value" }
  let(:controller) { instance_double(BytestreamsController) }
  let(:remote_ip) { "127.0.0.1" }
  let(:solr_document) { SolrDocument.new(solr_hash) }
  let(:solr_hash) { {} }
  let(:token_authorizer) { instance_double(Iiif::Authz::V2::ProbeService::Response::TokenAuthorizer) }
  let(:user) { instance_double(User) }
  let(:probe_response_status) { probe_response.to_h[:status] }
  let(:probe_response_location) { probe_response.to_h[:location] }
  let(:probe_response_format) { probe_response.to_h[:format] }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:bytestream_probe_url)
  end

  context "authorized without token" do
    before do
      allow(token_authorizer).to receive(:can_access_asset?).and_return(false)
      allow(controller).to receive(:can?).and_return(true)
      allow(controller).to receive(:bytestream_content_url)
    end
    it { expect(probe_response_status).to eql(302) }
  end
  context "token authorized" do
    before do
      allow(token_authorizer).to receive(:can_access_asset?).and_return(true)
      allow(controller).to receive(:bytestream_content_url)
    end
    it { expect(probe_response_status).to eql(302) }
    context 'solr document is an image' do
      let(:well_known_pid) { 'some:pid' }
      let(:solr_hash) { { dc_type_ssm: ['StillImage'], id: well_known_pid, fedora_pid_uri_ssi: "info:fedora/#{well_known_pid}" } }
      it 'returns a 302 for the image info doc' do
        expect(probe_response_status).to eql(302)
        expect(probe_response_location).to end_with("#{well_known_pid}/info.json")
        expect(probe_response_format).to eql('application/json+ld')
      end
    end
  end
  context "not authorized" do
    before do
      allow(token_authorizer).to receive(:can_access_asset?).and_return(false)
      allow(controller).to receive(:can?).and_return(false)
    end
    context "not logged in" do
      let(:user) { nil }
      context "object has id policy" do
        let(:solr_hash) {
          {
            'access_control_levels_ssim' => [Dcv::AccessLevels::ACCESS_LEVEL_AFFILIATION],
          }
        }
        before do
          allow(probe_response).to receive(:services)
        end
        it { expect(probe_response_status).to eql(401) }
      end
    end
    context "no token" do
      context "object has id policy" do
        it { expect(probe_response_status).to eql(403) }
      end
    end
  end
end