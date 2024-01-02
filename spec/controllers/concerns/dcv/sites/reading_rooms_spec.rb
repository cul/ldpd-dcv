require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')

describe ApplicationController, type: :controller do
	
	controller do
		include Dcv::Sites::ReadingRooms
	end

	let(:avery_id) { 'NNC-A' }
	let(:avery_uri) { 'info://avery.library.columbia.edu' }
	let(:rbml_id) { 'NNC-RB' }
	let(:rbml_uri) { 'info://rbml.library.columbia.edu' }
	let(:unauth_id) { 'NNC-NO' }

	describe '#location_uris_for_client' do
		it 'returns repository ids associated with the remote ip of the request' do
			expect(controller.request.remote_ip).to eql("0.0.0.0")
			expect(controller.location_uris_for_client).to eql([avery_uri, rbml_uri])
		end
	end

	describe '#repository_ids_for_client' do
		it 'returns repository ids associated with the remote ip of the request' do
			expect(controller.request.remote_ip).to eql("0.0.0.0")
			expect(controller.repository_ids_for_client).to eql([avery_id, rbml_id])
		end
	end

	describe '#reading_room_client?' do
		it 'returns false when there is not reading room param' do
			expect(controller.request.remote_ip).to eql("0.0.0.0")
			expect(controller.reading_room_client?).to be false
		end
		context 'there is a reading room param' do
			context 'the reading room is authorized for client' do
				before do
					controller.params[:repository_id] = rbml_id
				end
				it 'returns false' do
					expect(controller.reading_room_client?).to be true
				end
			end
			context 'the reading room is not authorized for client' do
				before do
					controller.params[:repository_id] = unauth_id
				end
				it 'returns false' do
					expect(controller.reading_room_client?).to be false
				end
			end
		end
	end
end
