require 'rails_helper'

RSpec.describe 'Api::V1::ExternalDisplayController', type: :request do
  describe 'GET /api/v1/external_display/info' do
    let(:item_id) { '123' }
    let(:asset_id) { 'abc' }

    let(:response_data) do
      {
        requested_at: Time.current.iso8601,
        document_one: {
          id: item_id,
          identifier: item_id,
          title: 'Test Item'
        },
        document_two: {
          id: asset_id,
          identifier: asset_id,
          title: 'Test Asset'
        }
      }
    end

    let(:error_message) { 'Record not found' }
    let(:error_code) { nil }
    let(:status) { nil }

    let(:service_result) do
      instance_double(
        Api::InfoService::Result,
        success?: success,
        data: response_data,
        error_message: error_message,
        error_code: error_code,
        status: status
      )
    end

    let(:service) do
      instance_double(Api::InfoService, call: service_result)
    end

    before do
      allow(Api::InfoService)
        .to receive(:new)
        .and_return(service)
    end

    def json
      JSON.parse(response.body)
    end

    context 'when the request is successful' do
      let(:success) { true }

      it 'returns a successful response with JSON data' do
        get '/api/v1/external_display/info',
            params: {
              itemId: item_id,
              assetId: asset_id
            }

        expect(response).to have_http_status(:ok)

        expect(json).to eq(
          'requested_at' => response_data[:requested_at],
          'document_one' => {
            'id' => item_id,
            'identifier' => item_id,
            'title' => 'Test Item'
          },
          'document_two' => {
            'id' => asset_id,
            'identifier' => asset_id,
            'title' => 'Test Asset'
          }
        )

        expect(Api::InfoService).to have_received(:new).with(
          item_id,
          asset_id
        )
      end
    end

    context 'when the service fails' do
      let(:success) { false }
      let(:error_code) { 'not_found' }
      let(:status) { :not_found }

      it 'returns a not found response' do
        get '/api/v1/external_display/info',
            params: {
              itemId: item_id,
              assetId: asset_id
            }

        expect(response).to have_http_status(:not_found)

        expect(json).to eq(
          'error' => {
            'code' => 'not_found',
            'message' => error_message
          }
        )
      end
    end

    context 'when itemId is missing' do
      let(:success) { true }

      it 'returns bad request' do
        get '/api/v1/external_display/info',
            params: {
              assetId: asset_id
            }

        expect(response).to have_http_status(:bad_request)

        expect(json['error']['code']).to eq('missing_parameter')
        expect(json['error']['message']).to include('itemId')
      end
    end

    context 'when assetId is missing' do
      let(:success) { true }

      it 'returns bad request' do
        get '/api/v1/external_display/info',
            params: {
              itemId: item_id
            }

        expect(response).to have_http_status(:bad_request)

        expect(json['error']['code']).to eq('missing_parameter')
        expect(json['error']['message']).to include('assetId')
      end
    end

    context 'when itemId is blank' do
      let(:success) { true }

      it 'returns bad request' do
        get '/api/v1/external_display/info',
            params: {
              itemId: '',
              assetId: asset_id
            }

        expect(response).to have_http_status(:bad_request)

        expect(json).to eq(
          'error' => {
            'code' => 'missing_parameter',
            'message' => 'param is missing or the value is empty: itemId'
          }
        )
      end
    end

    context 'when assetId is blank' do
      let(:success) { true }

      it 'returns bad request' do
        get '/api/v1/external_display/info',
            params: {
              itemId: item_id,
              assetId: ''
            }

        expect(response).to have_http_status(:bad_request)

        expect(json).to eq(
          'error' => {
            'code' => 'missing_parameter',
            'message' => 'param is missing or the value is empty: assetId'
          }
        )
      end
    end
  end
end