# frozen_string_literal: true

require 'rails_helper'

describe Api::UsersController, type: :request do
  let(:headers) { { "ACCEPT" => "application/json" } }

  let!(:site) { FactoryBot.create(:site_with_pages, slug: 'test_site') }

  # GET /api/v1/sites
  describe '#get_all_pages' do
    let(:endpoint) { '/api/v1/sites/test_site/pages' }

    context 'when authorized user' do
      include_context 'as admin user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns expected data' do
        expect(parse_resp(response)[:pages].length).to eq(3)
      end
    end

    context 'when unauthorized user' do
      include_context 'as non-privileged user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 403 status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      before do
        get endpoint, headers: headers
      end
      
      it 'returns 401 status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # PATCH api/v1/sites/:site_slug/pages
  describe '#patch_multiple' do
    let(:endpoint) { '/api/v1/sites/test_site/pages' }
    let(:params) do
      {
        pages: [
          {
            site_slug: 'test_site',
            page_slug: 'dlc_site_page',
            title: 'TEST CHANGE',
          }
        ]
      }
    end

    context 'when authorized user' do
      include_context 'as admin user'

      context 'with valid data' do
        before do
          patch endpoint, headers: headers, params: params
        end

        it 'returns 200 status' do
          expect(response).to have_http_status(:ok)
        end

        it 'updates changed page data' do
          page = SitePage.all.select { |p| p[:site_id] == site.id }.first
          expect(page[:title]).to eq('TEST CHANGE')
        end

        it 'deletes removed pages' do
          pages = SitePage.all.select { |p| p[:site_id] == site.id }
          expect(pages.length).to eq(1)
        end
      end

      context "with invalid data (page doesn't exist)" do
        before do
          allow_any_instance_of(SitePage).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
          patch endpoint, headers: headers, params: params
        end

        it 'returns 422 error status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'has an error message' do
          expect(parse_resp(response)[:error]).not_to be_nil
        end
      end
    end

    context 'when unauthorized user' do
      include_context 'as non-privileged user'
      before do
        patch endpoint, headers: headers, params: params
      end

      it 'returns 403 status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      before do
        patch endpoint, headers: headers
      end
      
      it 'returns 401 status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # DELETE api/v1/sites/:site_slug/pages/:page_slug
  describe '#delete' do
    let(:page_slug) { 'dlc_site_page'}
    let(:endpoint) { "/api/v1/sites/test_site/pages/#{page_slug}" }

    context 'when authorized user' do
      include_context 'as admin user'
      context 'with valid page slug' do
        before do
          delete endpoint, headers: headers
        end

        it 'returns 200 status' do
          expect(response).to have_http_status(:ok)
        end

        it 'deletes the page' do
          expect(SitePage.find_by(slug: page_slug)).to be_nil
        end

        it 'deletes only that page' do
          expect(SitePage.find_by(slug: 'another_page')).not_to be_nil
        end

        it 'responds with success message' do
          expect(parse_resp(response)[:message]).to include('success')
        end
      end

      context 'when trying to delete home slug' do
        let(:page_slug) { 'home'}
        let(:endpoint) { "/api/v1/sites/test_site/pages/#{page_slug}" }
        before do
          delete endpoint, headers: headers
        end

        it 'responds with a 403 status' do
          expect(response).to have_http_status(:forbidden)
        end

        it 'responds with an error message' do
          expect(parse_resp(response)[:error]).not_to be_nil
        end
      end

      context 'when trying to delete a page that prevents deletion' do
        let(:page_slug) { 'dlc_site_page'}
        let(:endpoint) { "/api/v1/sites/test_site/pages/#{page_slug}" }
        before do
          allow_any_instance_of(SitePage).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
          delete endpoint, headers: headers
        end

        it 'responds with a 422 error' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'responds with an error message' do
          expect(parse_resp(response)[:error]).not_to be_nil
        end

      end

      context 'when trying to delete non-existent page' do
        let(:page_slug) { 'DNE'}
        let(:endpoint) { "/api/v1/sites/test_site/pages/#{page_slug}" }
        before do
          delete endpoint, headers: headers
        end

        it 'responds with a 404 status' do
          expect(response).to have_http_status(:not_found)
        end

        it 'responds with an error message' do
          expect(parse_resp(response)[:error]).not_to be_nil
        end
      end
    end

    context 'when unauthorized user' do
      include_context 'as non-privileged user'
      before do
        delete endpoint, headers: headers
      end

      it 'returns 403 status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      before do
        delete endpoint, headers: headers
      end
      
      it 'returns 401 status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end