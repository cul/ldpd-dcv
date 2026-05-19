# frozen_string_literal: true

require 'rails_helper'

describe Admin::UploadsController, type: :request do
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:editor) { FactoryBot.create(:user, uid: 'editor_uid') }
  let(:user) { FactoryBot.create(:user) }

  describe 'GET admin/import' do
    context 'when authenticated admin' do
      it 'returns status OK' do
        sign_in admin
        get '/admin/import'
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when authenticated editor' do
      context 'in non-prod environment' do
        it 'returns status OK' do
          FactoryBot.create(:site, slug: 'dlc_site', title: 'Existing DLC Site', editor_uids: ['editor_uid'])
          sign_in editor
          get '/admin/import'
          expect(response).to have_http_status(:ok)
        end
      end
      context 'in dlc_prod environment' do
        it 'redirects to sign_in' do
          allow(Rails.env).to receive(:dlc_prod?).and_return(true)
          FactoryBot.create(:site, slug: 'dlc_site', title: 'Existing DLC Site', editor_uids: ['editor_uid'])
          sign_in editor
          get '/admin/import'
          expect(response).to redirect_to('/sign_in?referer=%2Fadmin%2Fimport')
        end
      end
    end

    context 'when authenticated non-privileged user' do
      it 'redirects to /sign_in' do
        sign_in user
        get '/admin/import'
        expect(response).to redirect_to('/sign_in?referer=%2Fadmin%2Fimport')
      end
    end

    context 'when unauthenticated user' do
      it 'redirects to /sign_in' do
        get '/admin/import'
        expect(response).to redirect_to('/sign_in')
      end
    end
  end

  describe 'POST /admin/upload' do
    let(:test_import_path) { File.join(fixture_path, 'test_import.zip') }
    let(:mock_upload) { instance_double(ActionDispatch::Http::UploadedFile) }
    let(:mock_import) { instance_double(SubsiteImportService) }

    context 'when authenticated non-privileged user' do
      it 'redirects to sign_in' do
        sign_in user
        post '/admin/upload'
        expect(response).to redirect_to('/sign_in?referer=%2Fadmin%2Fupload')
      end
    end

    context 'when unauthenticated' do
      it 'redirects to sign_in' do
        post '/admin/upload'
        expect(response).to redirect_to('/sign_in')
      end
    end

    context 'in dlc_prod environment' do
      before do
        FactoryBot.create(:site, slug: 'dlc_site', title: 'Existing DLC Site', editor_uids: ['editor_uid'])
        allow(Rails.env).to receive(:dlc_prod?).and_return(true)
      end

      it 'does not authorize dlc site editors' do
        sign_in editor
        post '/admin/upload'
        expect(response).to redirect_to('/sign_in?referer=%2Fadmin%2Fupload')
      end
    end

    context 'with a valid upload' do
      before do
        sign_in admin
        allow(SubsiteImportService).to receive(:new).and_return(mock_import)
        allow(mock_import).to receive(:import_subsite).and_return(nil)
        allow(mock_import).to receive(:finish_message).and_return('test message')

        post '/admin/upload', params: { upload: mock_upload }
      end

      it 'redirects to admin import path' do
        expect(response).to redirect_to('/admin/import')
      end

      it 'sets the flash success message' do
        expect(flash[:success]).to include('Your upload is complete')
      end
    end

    context 'with an invalid upload' do
      before do
        sign_in admin
        allow(SubsiteImportService).to receive(:new).and_return(mock_import)
        allow(mock_import).to receive(:import_subsite).and_raise(Exceptions::SubsiteUploadError, 'Test error')

        post '/admin/upload', params: { upload: mock_upload }
      end

      it 'redirects to sign_in' do
        expect(response).to redirect_to('/admin/import')
      end

      it 'sets the flash error message' do
        expect(flash[:error]).to include('Test error')
      end
    end
  end
end
