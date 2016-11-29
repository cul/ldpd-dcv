require 'rails_helper'

describe Dcv::RestrictableController, type: :unit do
  let(:test_class) do
    Class.new(ApplicationController) do
      include Dcv::RestrictableController

      def self.controller_path
        @controller_path
      end
    end
  end
  subject do
    test_class.new
  end
  context 'unrestricted' do
    before do
      subject.class.instance_variable_set(:@controller_path, 'test')
    end
    it { is_expected.not_to be_restricted }
  end
  context 'restricted' do
    before do
      subject.class.instance_variable_set(:@controller_path, 'restricted/test')
    end
    it { is_expected.to be_restricted }
  end
end
