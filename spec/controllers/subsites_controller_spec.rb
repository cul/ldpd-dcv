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
      expect(controller.subsite_styles).to include("gallery-#{Dcv::Sites::Constants.default_palette}")
      expect(controller.subsite_styles).to include('catalog')
    end
  end

  describe '#update' do
    subject do
      put :update, params: params
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
      delete :destroy, params: params
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

  describe '#page' do
    let(:api_key) { nil }
    let(:page) { double(SitePage, slug: slug) }
    let(:params) { { slug: slug } }
    let(:slug) { 'about' }

    before do
      controller.instance_variable_set(:@page, page)
      expect(controller).to receive(:load_page)
    end

    it "works" do
      expect(controller).to receive(:render)
      get :page, params: params
      expect(response.status).to eql(200)
    end

    context "with a nonexistent slug" do
      let(:page) { nil }
      let(:slug) { 'nonexistent' }

      it "404s" do
        expect(controller).to receive(:render).with(status: :not_found, plain: "Page Not Found")
        get :page, params: params
      end
    end
  end

  describe '#index' do
    let(:api_key) { nil }
    let(:doc1) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_1.json').read) }
    let(:doc2) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_2.json').read) }
    let(:doc3) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_3.json').read) }
    let(:params) {
      {
        format: 'json',
        q: '',
        search_field: 'all_text_teim'
      }
    }
    let(:document_list) { [
      SolrDocument.new(doc1),
      SolrDocument.new(doc2),
      SolrDocument.new(doc3)
    ] }
    let(:pagination_stubs) {
      {
        prev_page: nil, next_page: nil, total_pages: 1, current_page: 1, limit_value: 10, total_count: document_list.length,
        offset_value: 0, :first_page? => true, :last_page? => true
      }
    }
    let(:solr_response) {
      instance_double(Blacklight::Solr::Response, documents: document_list, aggregations: {}, **pagination_stubs)
    }
    let(:search_service) { instance_double(Dcv::SearchService) }

    context 'json format is requested' do
      let(:json_response) { JSON.parse(response.body) }
      before do
        # skip access control related to cul_omniauth/roles.yml
        allow(controller).to receive(:store_unless_user).and_return nil
        allow(controller).to receive(:authorize_action).and_return true
        allow(controller).to receive(:search_service).and_return(search_service)
        # mock search_results for the Blacklight search
        allow(search_service).to receive(:search_results).once.and_return(
          [solr_response, document_list],
        )
      end

      render_views

      it "responds without error" do
        get :index, params: params
        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq("application/json; charset=utf-8")
        expect(json_response.dig('data', 0, 'links', 'self')).to end_with(doc1['id'])
      end
    end
  end
end
