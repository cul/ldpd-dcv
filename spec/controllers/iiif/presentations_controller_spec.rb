require 'rails_helper'

describe Iiif::PresentationsController, type: :controller do
  let(:solr_doc) { double(SolrDocument) }

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:response).and_return(response)
    allow(controller).to receive(:fetch_by_doi).with(any_args).and_return(solr_doc)
  end

  context 'in an archivesspace collection' do
    let(:params) {
      {
        version: 3, registrant: '10.doi', doi: '123',
        archives_space_id: '1234567890abcdeffedcba9876543210',
        manifest_registrant: '10.manifest', manifest_doi: '123', format: 'json'
      }
    }

    describe '#aspace_collection' do
      before { allow_any_instance_of(Iiif::Collection::ArchivesSpaceCollection).to receive(:as_json).and_return({}) }

      render_views

      it 'renders' do
        get :aspace_collection, params: params
        expect(response).to have_http_status(200)
      end
    end
  end

  context 'file system or folder proxy collection' do
    let(:params) {
      {
        version: 3, registrant: '10.doi', doi: '123',
        collection_registrant: '10.collection', collection_doi: '123',
        manifest_registrant: '10.manifest', manifest_doi: '123', format: 'json'
      }
    }

    describe '#proxy_collection' do
      before { allow_any_instance_of(Iiif::Collection::ProxyCollection).to receive(:as_json).and_return({}) }

      render_views

      it 'renders' do
        get :proxy_collection, params: params
        expect(response).to have_http_status(200)
      end
    end
  end
end
