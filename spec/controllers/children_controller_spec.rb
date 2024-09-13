require 'rails_helper'

describe ChildrenController, type: :unit do
	let(:child_doc) { {} }
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
		)
	}
	let(:remote_ip) { '255.255.255.255' }
	let(:request_double) { instance_double('ActionDispatch::Request') }
	let(:search_service_double) { instance_double('Blacklight::SearchService') }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:remote_ip).and_return(remote_ip)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(search_service_double).to receive(:fetch).and_return([{}, child_doc])
		allow(controller).to receive(:search_service).and_return(search_service_double)
	end

	describe '#show' do
		let(:child_id) { 'test:child' }
		let(:child_doc) { { 'id' => child_id, 'title_ssm' => [child_title] } }
		let(:child_thumbnail) { "http://localhost/iiif/2/#{child_id}/full/!768,768/0/native.jpg" }
		let(:child_title) { 'test:child title' }
		let(:params) {
			ActionController::Parameters.new(
				parent_id: 'test:parent',
				id: 'test:child'
			)
		}
		it do
			expect(controller).to receive(:render).with(content_type: 'application/json', json: {
				datastreams_ssim: [],
				dc_type: nil,
				id: child_id,
				lib_item_in_context_url_ssm: [],
				pid: child_id,
				publisher_ssim: [],
				thumbnail: child_thumbnail,
				title: child_title
			})
			expect { controller.show }.not_to raise_error
		end
	end
end
