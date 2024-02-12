# frozen_string_literal: true
require 'rails_helper'

describe Dcv::Configurators::BaseBlacklightConfigurator do
  let(:config) do
    Blacklight::Configuration.new
  end
  let(:configurator) { Class.new { include Dcv::Configurators::BaseBlacklightConfigurator }.new }

  describe 'default_faceting_configuration' do
    context 'a facet has separate key and field values' do
      before do
        config.add_facet_field 'keyed_facet', field: 'facet_field'
        config.add_facet_field 'unkeyed_facet'
        configurator.default_faceting_configuration(config)
      end

      it 'only includes the field values in facet.field' do
        expect(config.default_solr_params['facet.field']).to include('unkeyed_facet')
        expect(config.default_solr_params['facet.field']).not_to include('keyed_facet')
        expect(config.default_solr_params['facet.field']).to include('facet_field')
      end
    end
  end
end