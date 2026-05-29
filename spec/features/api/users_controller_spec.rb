# frozen_string_literal: true

require 'rails_helper'

describe Api::UsersController, type: :request do
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:editor) { FactoryBot.create(:user, uid: 'te123') }
  let(:user) { FactoryBot.create(:user, uid: 'tu123') }
  
  before do
    FactoryBot.create(:site, editor_uids: ['te123'], slug: 'test_site')
  end
  
  describe '#_self' do
    let(:endpoint) { '/api/v1/users/_self'}
    let(:headers) { { "ACCEPT" => "application/json" } }

    context 'when unauthenticated' do
      it 'returns 401' do
        get endpoint, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context 'when admin' do
      before do
        sign_in admin
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'has admin role in permission hash' do
        expect(JSON.parse(response.body)["user"]["permissions"]["role"]).to eq(Api::UsersController::ROLES[:admin])
      end
    end

    context 'when editor' do
      before do
        sign_in editor
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'has editor role in permissions hash' do
        expect(JSON.parse(response.body)["user"]["permissions"]["role"]).to eq(Api::UsersController::ROLES[:editor])
      end

      it 'lists correct can_edit sites in permissions hash' do
        expect(JSON.parse(response.body)["user"]["permissions"]["canEdit"]).to include('test_site')
      end
    end

    context 'when normal user' do
      before do
        sign_in user
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end
      
      it 'has user role in permissions hash' do
        expect(JSON.parse(response.body)["user"]["permissions"]["role"]).to eq(Api::UsersController::ROLES[:user])
      end
      it 'has empty can_edit sites list in permissions hash' do
        expect(JSON.parse(response.body)["user"]["permissions"]["canEdit"]).to be_empty
      end
    end
  end
end
