require 'rails_helper'

describe CatalogController, :type => :controller do
  before do
    controller.subsite_config['remote_request_api_key'] = valid_api_key
    request.env['HTTP_AUTHORIZATION'] = api_key
    allow(IndexFedoraObjectJob).to receive(:perform).
      with(hash_including('pid' => 'baad:id')).
      and_raise(ActiveFedora::ObjectNotFoundError)
  end
  after do
    controller.subsite_config['remote_request_api_key'] = SUBSITES.dig('public', 'catalog', 'remote_request_api_key')
  end
  let(:valid_api_key) { 'goodtoken' }
  let(:invalid_api_key) { valid_api_key + 'gonebad' }
  let(:mock_object) do
    double(ActiveFedora::Base)
  end

  describe '#subsite_styles' do
    let(:api_key) { nil }
    before do
      FactoryBot.create(:site, slug: 'catalog', layout: 'gallery', palette: 'monochromeDark')
    end
    it "includes both the common styles and custom styles" do
      expect(controller.load_subsite.layout).to eql('gallery')
      expect(controller.subsite_styles).to include('gallery-monochromeDark')
      expect(controller.subsite_styles).to include('catalog')
    end
  end

  describe '#update' do
    subject do
      put :update, params
      response.status
    end
    context 'no api_key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(invalid_api_key)
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(valid_api_key)
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(404) }
      end
      context 'good doc id' do
        let(:mock_object) do
          double(ActiveFedora::Base)
        end
        let(:mock_id) { 'good:id' }
        let(:mock_doi) { 'doi:10.1234/567-abc' }
        let(:solr_doc) { SolrDocument.new(id: mock_id, ezid_doi_ssim: [mock_doi]) }
        let(:params) { { id: mock_id } }
        before do
          expect(IndexFedoraObjectJob).to receive(:perform).with(hash_including('pid' => mock_id, 'reraise' => true)).and_return(solr_doc)
        end
        it do
          expect(subject).to eql(200)
        end
      end
      context 'good doc id, bad data' do
        let(:mock_object) do
          double(ActiveFedora::Base)
        end
        let(:params) { { id: 'good:id' } }
        before do
          expect(IndexFedoraObjectJob)
          .to receive(:perform).with(hash_including('pid' => 'good:id', 'reraise' => true))
          .and_raise(Encoding::UndefinedConversionError)

          expect(Rails.logger).to receive(:error)
        end
        it do
          expect(subject).to eql(500)
        end
      end
    end
  end
  describe '#destroy' do
    let(:rsolr) { double('RSolr') }
    #TODO: Determine if RSolr signals a missing id on delete
    let(:bad_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    let(:good_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    before do
      allow(controller).to receive(:rsolr).and_return(rsolr)
    end
    subject do
      delete :destroy, params
      response.status
    end
    context 'no api_key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(invalid_api_key)
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api_key' do
      before do
        allow(solr_repo).to receive(:connection).and_return(rsolr)
        allow(rsolr).to receive(:delete_by_id).with('baad:id').and_return(bad_id_response)
        allow(rsolr).to receive(:delete_by_id).with('good:id').and_return(good_id_response)
        allow(rsolr).to receive(:commit)
        Blacklight.default_index = solr_repo
      end
      after { Blacklight.default_index = nil }
      let(:solr_repo) { instance_double(Blacklight::Solr::Repository) }
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(valid_api_key)
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(200) }
      end
      context 'good doc id' do
        let(:params) { { id: 'good:id' } }
        it { is_expected.to eql(200) }
      end
    end
  end
end
