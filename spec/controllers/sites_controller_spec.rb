require 'rails_helper'

describe SitesController, type: :unit do
	describe '#site_params' do
		let(:controller) { described_class.new }
		before { allow(controller).to receive(:params).and_return(params) }
		context 'with blank image_uris values' do
			let(:params) {
				ActionController::Parameters.new(
					site: {
						image_uris: ['a', nil, 'b', '', 'c']
					}
				)
			}
			let(:update_params) { controller.send :site_params }
			it "compacts the values" do
				expect(update_params[:image_uris]).to eql(['a', 'b', 'c'])
			end
		end
	end
end
