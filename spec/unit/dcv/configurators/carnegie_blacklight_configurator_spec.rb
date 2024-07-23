# frozen_string_literal: true
require 'rails_helper'

describe Dcv::Configurators::CarnegieBlacklightConfigurator do
  let(:config) do
    Blacklight::Configuration.new
  end
  let(:configurator) { Class.new { include Dcv::Configurators::BaseBlacklightConfigurator }.new }

  describe 'fulltext search configuration' do
    context 'flag is default' do
      before do
        described_class.configure(config)
      end

      it 'only includes the field values in facet.field' do
        expect(config.search_fields['fulltext_tesim']).to be_a Blacklight::Configuration::SearchField
      end
    end
    context 'flag is true' do
      before do
        described_class.configure(config, fulltext: true)
      end

      it 'only includes the field values in facet.field' do
        expect(config.search_fields['fulltext_tesim']).to be_a Blacklight::Configuration::SearchField
      end
    end
    context 'flag is false, as per centennial site' do
      before do
        described_class.configure(config, fulltext: false)
      end

      it 'only includes the field values in facet.field' do
        expect(config.search_fields['fulltext_tesim']).to be_nil
      end
    end
  end
end