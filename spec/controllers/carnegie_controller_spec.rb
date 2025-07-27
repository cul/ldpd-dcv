require 'rails_helper'

describe CarnegieController, type: :controller do
  before do
    expect(controller).not_to be_nil
    expect(controller.controller_name).not_to be_nil
  end

  describe '#blacklight_config' do
    describe '.show.disclaimer_component' do
      let(:actual_class) { controller.blacklight_config.show.disclaimer_component }
      let(:expected_class) { Dcv::Alerts::Disclaimers::CarnegieComponent }
      it 'includes a custom disclaimer component' do
        expect(actual_class).to be(expected_class)
      end
    end
  end
end
