require "rails_helper"

describe 'shared/_show_content_aggregator', type: :view do
  include_context "a solr document"

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:document) { solr_document }

  let(:citation_presenter) { instance_double(Dcv::CitationPresenter, fields_to_render: {}) }
  let(:document_presenter) { instance_double(Dcv::ShowPresenter, fields_to_render: {}) }

  let(:disclaimer_component_class) do
    Class.new(Dcv::Alerts::Disclaimers::DefaultComponent) do
      def render?
        true
      end
      def render_in(_view_context, &_block)
        "<p class=\"disclaimer\">FYI</p>".html_safe
      end
    end
  end

  subject { rendered }

  before do
    blacklight_config.show.disclaimer_component = disclaimer_component_class
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:document).and_return(document)
    allow(view).to receive(:citation_presenter).and_return(citation_presenter)
    allow(view).to receive(:document_presenter).and_return(document_presenter)
    stub_template "content_aggregator/_viewer_panel" => "<div id=\"stub-viewer-panel\"></div>"
    render
  end

  it 'renders its top-level div' do
    expect(rendered).to have_selector "div[class='col px-0 ls-controls-dark']"
  end

  it 'renders its disclaimer' do
    expect(rendered).to have_selector "p[class='disclaimer']", text: 'FYI'
  end
end
