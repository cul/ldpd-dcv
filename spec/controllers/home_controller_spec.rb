require 'rails_helper'

describe HomeController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
		)
	}
	let(:request_double) { instance_double('ActionDispatch::Request') }
	let(:remote_ip) { '255.255.255.255' }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:remote_ip).and_return(remote_ip)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
	end

	describe '#authorize_action' do
		let(:location_uris) { [] }
		let(:ability_double) { instance_double(Ability) }
		before do
			expect(controller).to receive(:current_ability).and_return(ability_double)
			expect(ability_double).to receive(:ip_to_location_uris).with(remote_ip).and_return(location_uris)
		end
		context 'from any mapped location' do
			let(:location_uris) { ['http://any.value'] }
			it do
				expect(controller).not_to receive(:current_user)
				expect {controller.authorize_action }.not_to raise_error(CanCan::AccessDenied)
			end
		end
		context 'with any current user' do
			it do
				expect(controller).to receive(:current_user).and_return(instance_double(User))
				expect {controller.authorize_action }.not_to raise_error(CanCan::AccessDenied)
			end
		end
		context 'with no location or user' do
			it do
				expect(controller).to receive(:current_user).and_return(nil)
				expect {controller.authorize_action }.to raise_error(CanCan::AccessDenied)
			end
		end
	end
end
