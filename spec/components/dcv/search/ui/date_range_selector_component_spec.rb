# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Dcv::Search::Ui::DateRangeSelectorComponent, type: :component do
  let(:component) { described_class.new(enabled: true) }

  let(:params_for_search) { { controller: 'catalog', action: 'index', q: 'testParamValue', start_year: 1024, end_year: 2048 } }
  let(:params) { ActionController::Parameters.new(params_for_search) }
  let(:date_range_segment_data) { { '1024' => []} }
  let(:subsite_config) do
    {
      'date_search_configuration' => {
        'show_timeline' => true
      }
    }
  end

  include_context "renderable view components"

  before do
    component.instance_variable_set(:@view_context, view_context)
    component.instance_variable_set(:@date_year_segment_data, date_range_segment_data)
    allow(component).to receive(:render?).and_return(true)
    allow(component).to receive(:get_date_year_segment_data_for_query)
    allow(view_context).to receive(:current_user)
    allow(view_context).to receive(:active_site_palette).and_return('blue')
    allow(controller).to receive(:params).and_return(params)
    # allow(controller).to receive(:subsite_config).and_return(subsite_config)
  end

  describe "reset_range_filter_params" do
    let(:reset_params) { component.reset_range_filter_params }
    it "returns linkable permitted filters" do
      expect(reset_params[:q]).to be_present
      expect(reset_params[:end_year]).not_to be_present
      expect(reset_params[:start_year]).not_to be_present
      expect(reset_params).to be_permitted
    end
  end

  it "renders" do
    expect(render).not_to be_blank
  end
end
