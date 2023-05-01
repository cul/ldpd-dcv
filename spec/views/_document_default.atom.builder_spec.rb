# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "shared/_document" do
  let(:author) { 'xyz' }
  let(:document) do
    doc = SolrDocument.new(id: 0)
    allow(doc).to receive(:to_semantic_values).and_return(author: [author])
    doc
  end

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:request_params) { {} }
  let(:search_state_class) do
    Class.new(Dcv::SearchState) do
      def url_for_document(doc, options = {})
        "/catalog/#{doc.id}"
      end
    end
  end
  let(:search_state) { search_state_class.new(request_params, blacklight_config, controller) }

  before do
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:action_name).and_return('index')
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "has basic data" do
    render template: 'shared/_document_default', formats: [:atom], locals: { document: document, document_counter: 1 }

    expect(rendered).to have_selector("entry/title")
    expect(rendered).to have_selector("entry/author/name", text: author)
    expect(rendered).to have_selector("link[type='text/html']")
  end
end