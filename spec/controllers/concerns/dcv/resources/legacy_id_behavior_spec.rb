require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')

describe Dcv::Resources::LegacyIdBehavior, type: :unit do
  
  before do
    class TestRig
      attr_reader :params

      def self.rescue_from(*args)
      end
      
      include Dcv::Resources::LegacyIdBehavior

      def initialize(id, params={})
        @document = {id: id}
        @params = params
      end

      def get_solr_response_for_app_id
        # this is a no-op stub
      end
    end

  end
  after do
    Object.send :remove_const, :TestRig
  end
  subject(:controller) { TestRig.new('lol:wut') }
  let(:expected_url) { 'get:lol:wut' }
  it "should resolve resourceful actions correctly" do
    controller.params[:action] = 'spaceship'
    allow(controller).to receive(:spaceship_url).and_return(expected_url)
    expect(controller).to receive(:redirect_to).with(expected_url)
    controller.get
  end
end
