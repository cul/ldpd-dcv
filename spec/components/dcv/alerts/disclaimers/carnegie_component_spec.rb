# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::Alerts::Disclaimers::CarnegieComponent, type: :component do
  subject(:component) { described_class.new(document: document) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  include_context "a solr document"

  let(:document) { solr_document }
  let(:document_presenter) { Blacklight::ShowPresenter.new(solr_document, view_context) }

  context 'digital origin indicates digitized microfilm' do
    let(:solr_data) { { physical_description_digital_origin_ssm: ['digitized microfilm'] } }

    before do
      allow(view_context).to receive(:document_presenter).and_return(document_presenter)      
    end

    it 'disclaims contrast quality' do
      expect(rendered).to have_selector "em", text: /variable contrast quality/
    end
  end
end
