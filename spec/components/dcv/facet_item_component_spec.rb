# frozen_string_literal: true

require 'rails_helper'

describe Dcv::FacetItemComponent, type: :component do
  subject(:component) { described_class.new(facet_item: facet_item) }

  let(:facet_item) do
    instance_double(
      Blacklight::FacetItemPresenter,
      facet_config: Blacklight::Configuration::FacetField.new(**facet_config),
      label: 'x',
      value: 'x',
      hits: 10,
      href: '/catalog?f=x',
      selected?: false
    )
  end

  let(:facet_config) { {} }

  include_context "renderable view components"

  context "with a suppressed value" do
    let(:facet_config) { { 'cul_custom_value_hide' => ['x'] } }
    it 'renders nothing' do
      expect(render).to be_blank
    end
  end

  context "with a transformed value" do
    let(:facet_config) { { 'cul_custom_value_transforms' => ['capitalize'] } }
    it 'links to the facet and shows the number of hits' do
      expect(rendered).to have_selector 'li'
      expect(rendered).to have_link 'X', href: '/catalog?f=x'
      expect(rendered).to have_selector '.facet-count', text: '10'
    end
  end
end