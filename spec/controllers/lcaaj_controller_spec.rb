require 'rails_helper'

describe LcaajController, :type => :controller do
  before do
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
  end
  describe '#subsite_styles' do
    before do
      FactoryBot.create(:site, slug: 'lcaaj', layout: 'custom')
    end
    it "returns only custom styles" do
      expect(controller.load_subsite.layout).to eql('custom')
      expect(controller.subsite_styles).to eql(['signature-blue', 'lcaaj'])
    end
  end
  describe '#index' do
    context 'respond to csv' do
      let(:doc1) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_1.json').read) }
      let(:doc2) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_2.json').read) }
      let(:doc3) { JSON.parse(fixture('controllers/lcaaj_controller/sample_solr_doc_3.json').read) }
      let(:params) {
        {
          format: 'csv',
          q: '',
          search_field: 'all_text_teim'
        }
      }
      let(:document_list) { [
        SolrDocument.new(doc1),
        SolrDocument.new(doc2),
        SolrDocument.new(doc3)
      ] }
      let(:search_service) { instance_double(Dcv::SearchService) }

      let(:expected_csv_data_as_2d_array) { CSV.parse(fixture('controllers/lcaaj_controller/csv_for_solr_docs.csv').read) }
      it "responds with expected csv data" do
        # skip access control related to cul_omniauth/roles.yml
        allow(controller).to receive(:store_unless_user).and_return nil
        allow(controller).to receive(:authorize_action).and_return true
        allow(controller).to receive(:search_service).and_return(search_service)
        # mock search_results for the initial Blacklight search and the CSV streaming search of all records
        allow(search_service).to receive(:search_results).twice.and_return(
          [{}, document_list],
          [{}, document_list],
          [{}, []]
        )
        expected_csv_data_as_2d_array.each do |expected_csv_row|
          expect(controller).to receive(:write_csv_line_to_response_stream).once.with(
            contain_exactly(*expected_csv_row)
          )
        end
        get :index, params: params
        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq("text/csv")
        expect(response.headers['Content-Disposition']).to eq('attachment; filename="search_results.csv"')
      end
    end
  end

  describe '#write_csv_line_to_response_stream' do
    let(:stream) {
      mock_stream = double("stream")
      allow(mock_stream).to receive(:write)
      mock_stream
    }
    let(:response) {
      mock_response = double("response")
      allow(mock_response).to receive(:stream).and_return(stream)
      mock_response
    }
    it "converts an csv line array to a CSV line string" do
      allow(controller).to receive(:response).and_return(response)
      expect(stream).to receive(:write).once.with("\"Comma field with words, words, and more words\",Second Field,Third Field\n")
      controller.send(:write_csv_line_to_response_stream, ["Comma field with words, words, and more words", "Second Field", "Third Field"])
    end
  end
end
