# frozen_string_literal: true

require 'rails_helper'

describe Api::UsersController, type: :request do
  let(:headers) { { "ACCEPT" => "application/json" } }

  # GET /api/v1/sites
  describe '#get_sites' do
    let(:endpoint) { '/api/v1/sites' }

    before do
      FactoryBot.create(:site, editor_uids: ['te123'], slug: 'test_site')
      FactoryBot.create(:site, editor_uids: ['other_editor'], slug: 'test_site_2')
    end

    context 'when admin' do
      include_context 'as admin user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns all sites' do
        expect(parse_resp(response)["sites"].map(&:slug)).to include('test_site', 'test_site_2')
      end
    end
    context 'when editor' do
      include_context 'as editor user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns all sites' do
        expect(parse_resp(response)["sites"].map(&:slug)).to include('test_site')
      end
    end

    context 'when user' do
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

  # /api/v1/site/:site_slug
  describe '#get_site' do
    let(:endpoint) { '/api/v1/sites/test_site' }

    before do
      FactoryBot.create(:site, editor_uids: ['te123'], slug: 'test_site')
    end

    context 'when admin' do
      include_context 'as admin user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns expected data' do
        expect(parse_resp(response)[:site][:slug]).to eq('test_site')
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

      it 'returns expected data' do
        expect(parse_resp(response)[:site][:slug]).to eq('test_site')
      end
    end

    context 'when non-editor user' do
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

  describe 'get_site_nav_groups' do
    let(:endpoint) { '/api/v1/sites/test_site/nav_groups' }
    before do
      FactoryBot.create(:site_with_links, slug: 'test_site')
    end

    context 'when authorized' do
      include_context 'as admin user'
      before do
        get endpoint, headers: headers
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns expected group labels' do
        expect(parse_resp(response)[:navGroups].map(&:groupLabel)).to include('Project History', '')
      end

      it 'returns expected link labels' do
        parsed_resp = parse_resp(response)
        projectHistoryGroup = parsed_resp[:navGroups].find { |ng| ng[:groupLabel] == 'Project History' }
        aboutGroup = parsed_resp[:navGroups].find { |ng| ng[:groupLabel] == '' }

        expect(projectHistoryGroup[:childrenLinks].map(&:linkLabel)).to include('Contributors', 'Funding')
        expect(aboutGroup[:childrenLinks].map(&:linkLabel)).to include('About')
      end
    end

    context 'when non-editor user' do
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

  describe '#upload_signature_images' do
    let(:endpoint) { '/api/v1/sites/test_site/signature_images' }
    let!(:site) { FactoryBot.create(:site, slug: 'test_site') }
    
    context 'when authorized' do
      include_context 'as admin user'

      context 'with a good upload' do
        let(:fixture_file_path) { 'sites/import/directory/images/signature.svg' }
        let(:params) do
          {
            site: {
              watermark: fixture_file_upload(fixture_file_path),
              palette: 'default', # Need to have some value here so that strong params doesn't throw error on empty params
            }
          }
        end

        before do
          patch endpoint, headers: headers, params: params
        end
        after { FileUtils.rm_rf('public/images/sites/test_site/') }

        it 'returns 200 status' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns the updated site model' do
          expect(parse_resp(response)[:site][:watermarkImageUrl]).to include('/images/sites/test_site/signature.svg?v=')
        end
      end

      context 'with a bad upload' do
        let(:fixture_file_path) { "sites/import/directory/images/signature.svg" }
        let(:params) do
          {
            site: {
              banner: fixture_file_upload(fixture_file_path),
              palette: 'default', # Need to have some value here so that strong params doesn't throw error on empty params
            }
          }
        end

        before do
          patch endpoint, headers: headers, params: params
        end

        it 'returns 422 status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns an error json' do
          expect(JSON.parse(response.body)).to have_key('error')
        end

        it 'returns an error message' do
          expect(parse_resp(response)[:error]).to include('allowed types: png')
        end
      end
    end
    
    context 'when non-editor user' do
      include_context 'as non-privileged user'
      before do
        patch endpoint, headers: headers
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

  describe '#delete_signature_image' do
    let(:endpoint) { '/api/v1/sites/test_site/signature_images' }
    let(:watermark_endpoint) { "#{endpoint}/watermark" }
    let!(:site) { FactoryBot.create(:site, slug: 'test_site') }

    context 'when authorized' do
      include_context 'as admin user'

      context 'with valid data' do
        before do
          allow_any_instance_of(Api::SitesController).to receive(:load_subsite) do |controller|
            controller.instance_variable_set(:@subsite, site)
            site
          end
          allow_any_instance_of(Site).to receive(:has_watermark_image?).and_return(true)
          allow(FileUtils).to receive(:rm_f).and_return(nil)
          delete watermark_endpoint, headers: headers
        end

        it 'returns 200 status' do
          expect(response).to have_http_status(:ok)
        end
        
        it 'deletes the file' do
          expect(FileUtils).to have_received(:rm_f).once
        end
      end

      context 'with nonexistent data' do
        before do
          allow(site).to receive(:has_watermark_image?).and_return(false)
          delete watermark_endpoint, headers: headers
        end

        it 'returns 404 error' do
          expect(response).to have_http_status(:not_found)
        end

        it 'responds with json error object' do
          expect(JSON.parse(response.body)).to have_key('error')
        end

        it 'responds with meaningful error message' do
          expect(parse_resp(response)[:error]).to include('does not exist')
        end
      end

      context 'with bad image type data' do
        before do
          delete "#{endpoint}/bad", headers: headers
        end
        
        it 'returns 400' do
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'when non-editor user' do
      include_context 'as non-privileged user'
      before do
        delete watermark_endpoint, headers: headers
      end

      it 'returns 403 status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      before do
        delete watermark_endpoint, headers: headers
      end

      it 'returns 401 status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '#update' do
    let(:endpoint) { '/api/v1/sites/test_site' }
    let!(:site) { FactoryBot.create(:site_with_links, slug: 'test_site') }

    before do

    end

    context 'as authenticated user' do
      include_context 'as admin user'
      let(:params) do 
        { 
          site: {
            
        # create(:nav_link, site_id: site.id, external: false, link: 'about', sort_group: '00:', sort_label: '00:About')
        # create(:nav_link, site_id: site.id, external: false, link: 'funding', sort_group: '01:Project History', sort_label: '00:Funding')
        # create(:nav_link, site_id: site.id, external: false, link: 'contributors', sort_group: '01:Project History', sort_label: '01:Contributors')
            alternative_title: 'New Title!',
            nav_groups: [
              {
                # Editing an existing link
                group_label: '',
                children_links: [
                  {
                    link_label: 'About - test change',
                    link_value: 'about',
                  }
                ]
              },
              {
                group_label: 'new group',
                children_links: [
                  {
                    link_label: 'new link',
                    link_value: 'new link value',
                  }
                ],
              },
            ]
          }
        }
      end

      before do
        patch endpoint, headers: headers, params: params
      end

      context 'with valid data' do
        it 'returns status 200' do
          expect(response).to have_http_status(:ok)
        end

        it 'updates the site model data' do
          expect(Site.find_by(slug: 'test_site')[:alternative_title]).to eq('New Title!')
        end
        
        it 'adds new nav_links data' do
          new_link = Site.find_by(slug: 'test_site').nav_links.each { |nl| nl.link == 'new link value' }
          expect(new_link).not_to be_nil
        end

        it 'updates changed nav_links data' do
          updated_link = Site.find_by(slug: 'test_site').nav_links.detect { |nl| nl.link == 'about' }
          expect(updated_link[:sort_label]).to eq('00:About - test change')
        end

        it 'preserves existing nav_links data' do
          updated_link = Site.find_by(slug: 'test_site').nav_links.detect { |nl| nl.link == 'about' }
          expect(updated_link[:sort_group]).to eq('00:')
        end

        it 'deletes omitted existing nav_links data' do
          existing_link = Site.find_by(slug: 'test_site').nav_links.detect { |nl| nl.link == 'funding' }
          expect(existing_link).to be_nil
        end

      end

      # TODO: Here
      context 'with invalid data' do
        before do
          allow_any_instance_of(Site).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
          patch endpoint, headers: headers, params: params
        end

        it 'returns 422 error status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns an error message' do
          expect(parse_resp(response)[:error]).not_to be_nil
        end
      end
    end

    context 'when non-editor user' do
      include_context 'as non-privileged user'
      before do
        patch endpoint, headers: headers
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
end