require 'rails_helper'

describe Iiif::PresentationsController, type: :controller do
  let(:params) {
    {
      version: 3, registrant: '10.doi', doi: '123',
      collection_registrant: '10.collection', collection_doi: '123',
      manifest_registrant: '10.manifest', manifest_doi: '123', format: 'json'
    }
  }
  let(:solr_doc) { double(SolrDocument) }
  before do
    allow_any_instance_of(Iiif::Collection).to receive(:as_json).and_return({})

    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:response).and_return(response)
    allow(controller).to receive(:fetch_by_doi).with(any_args).and_return(solr_doc)
  end
  describe '#collection' do
    render_views
    it 'renders' do
      get :collection, params: params
      expect(response).to have_http_status(200)
    end
  end
end
