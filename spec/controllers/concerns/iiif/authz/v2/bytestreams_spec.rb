require 'rails_helper'

describe Iiif::Authz::V2::Bytestreams, type: :unit do
  let(:test_class) do
    Class.new(ApplicationController) do
      include Iiif::Authz::V2::Bytestreams
    end
  end

  subject(:controller) do
    test_class.new
  end

  describe '#has_probeable_resource?' do
    let(:bytestream_id) { 'content' }
    let(:params) { { bytestream_id: bytestream_id } }

    before do
      allow(controller).to receive(:params).and_return(params)      
    end

    it 'returns false when passed nil' do
      expect(controller.has_probeable_resource?(nil)).to be false
    end

    context 'has a SolrDocument' do
      let(:solr_doc) { instance_double(SolrDocument) }
      let(:resource_doc) { { id: "fedora/pid/#{bytestream_id}" } }

      context 'with resources' do
        before do
          allow(controller).to receive(:resources_for_document).with(solr_doc, false).and_return([resource_doc])
        end

        it 'works when #resources_for_document returns a present value' do
          expect(controller.has_probeable_resource?(solr_doc)).to be true
        end
      end

      context 'without resources' do
        let(:dc_type) { 'Software' }

        before do
          allow(solr_doc).to receive(:fetch).with('dc_type_ssm', []).and_return([dc_type])
          allow(controller).to receive(:resources_for_document).with(solr_doc, false).and_return([])
        end

        it 'returns false' do
          expect(controller.has_probeable_resource?(solr_doc)).to be false
        end

        context 'but an image dc type' do
          let(:dc_type) { 'StillImage' }
          
          it 'returns true' do
            expect(controller.has_probeable_resource?(solr_doc)).to be true
          end
        end
      end
    end
  end

  describe '#resource' do
    let(:authorization_header) { nil }
    let(:bytestream_id) { 'content' }
    let(:bytestream_content_url) { 'bytestream_content_url' }
    let(:bytestream_probe_url) { 'bytestream_probe_url' }
    let(:bytestream_token_url) { 'bytestream_token_url' }
    let(:current_user) { nil }
    let(:iiif_kiosk_url) { 'iiif_kiosk_url' }
    let(:iiif_login_url) { 'iiif_login_url' }
    let(:cache_control) { {} }
    let(:solr_doc_dc_type) { 'Text' }
    let(:request_headers) { instance_double(ActionDispatch::Http::Headers) }
    let(:response_headers) { instance_double(ActionDispatch::Http::Headers) }
    let(:origin_header) { 'localhost' }
    let(:params) { { bytestream_id: bytestream_id } }
    let(:remote_ip) { '0.0.0.0' }
    let(:request) { instance_double(ActionDispatch::Request, headers: request_headers, remote_ip: remote_ip,
      host: 'localhost', optional_port: nil, path_parameters: [], protocol: 'http') }
    let(:response) { instance_double(ActionDispatch::Response, headers: response_headers, cache_control: cache_control) }
    let(:solr_doc) { SolrDocument.new({
      id: 'solr-1', dc_type_ssm: [solr_doc_dc_type], title_display_ssm: ['title_display_ssm'],
      access_control_levels_ssim: [Dcv::AccessLevels::ACCESS_LEVEL_AFFILIATION]
    }) }

    before do
      allow(controller).to receive_messages(
        bytestream_content_url: bytestream_content_url, bytestream_probe_url: bytestream_probe_url, bytestream_token_url: bytestream_token_url,
        current_user: current_user, fetch: [nil, solr_doc], iiif_kiosk_url: iiif_kiosk_url, iiif_login_url: iiif_login_url,
        params: params, request: request, response: response, cors_headers: nil
      )
      allow(request_headers).to receive(:[]).with('Authorization').and_return(authorization_header)
      allow(request_headers).to receive(:[]).with('Origin').and_return(origin_header)
      allow(response_headers).to receive(:[]=).with('Cache-Control', String).and_return(true)
      allow(response_headers).to receive(:[]=).with('Access-Control-Allow-Origin', origin_header).and_return(origin_header)
      allow(response_headers).to receive(:[]=).with('Access-Control-Allow-Credentials', String).and_return(true)
      allow(response_headers).to receive(:[]=).with('Content-Type', String).and_return(true)
    end

    context 'request is authorized' do
      it 'redirects to probe response location with 302' do
        allow(controller).to receive(:can?).and_return(true)
        expect(controller).to receive(:redirect_to)
        controller.resource
      end
    end
    context 'request is denied' do
      it 'responds with nothing and passes 401 through' do
        allow(controller).to receive(:can?).and_return(false)
        expect(controller).to receive(:render).with({nothing: true, status: 401})
        controller.resource
      end
    end
  end
end
