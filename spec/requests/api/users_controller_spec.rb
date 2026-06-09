# frozen_string_literal: true

require 'rails_helper'

describe Api::UsersController, type: :request do
  before do
    # editor uid matches shared context mock editor user
    FactoryBot.create(:site, editor_uids: ['te123'], slug: 'test_site')
  end
  
  describe '#_self' do
    let(:endpoint) { '/api/v1/users/_self'}
    let(:headers) { { "ACCEPT" => "application/json" } }

    context 'when admin' do
      include_context 'as admin user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'has admin role in permission hash' do
        expect(parse_resp(response)[:user][:permissions][:role]).to eq(Api::UsersController::ROLES[:admin])
      end
    end

    context 'when editor' do
      include_context 'as editor user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'has editor role in permissions hash' do
        expect(parse_resp(response)[:user][:permissions][:role]).to eq(Api::UsersController::ROLES[:editor])
      end

      it 'lists correct can_edit sites in permissions hash' do
        expect(parse_resp(response)[:user][:permissions][:canEdit]).to include('test_site')
      end
    end

    context 'when normal user' do
      include_context 'as non-privileged user'

      before do
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end
      
      it 'has user role in permissions hash' do
        expect(parse_resp(response)[:user][:permissions][:role]).to eq(Api::UsersController::ROLES[:user])
      end
      it 'has empty can_edit sites list in permissions hash' do
        expect(parse_resp(response)[:user][:permissions][:canEdit]).to be_empty
      end
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        get endpoint, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
