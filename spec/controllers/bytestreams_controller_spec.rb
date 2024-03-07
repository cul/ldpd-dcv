require 'rails_helper'

describe BytestreamsController, type: :unit do
	let(:controller) { described_class.new }

	let(:fedora_pid) { 'test:gr' }
	let(:bytestream_id) { 'content' }
	let(:rubydora_repository) do
		Rubydora::Repository.new({}, SingleObjectFcrApi.new(foxml))
	end
	let(:rubydora_object) { ActiveFedora::DigitalObject.new(fedora_pid, rubydora_repository) }
	let(:active_fedora_object) do
		::ActiveFedora::Base.allocate.init_with_object(rubydora_object)
	end
	let(:foxml) { fixture("foxml/#{fedora_pid.sub(':','_')}.xml").read }
	let(:solr_adapter) { Dcv::Solr::DocumentAdapter::ActiveFedora(active_fedora_object) }
	let(:solr_doc) { solr_adapter.to_solr }
	let(:permitted_params) {
		{ catalog_id: fedora_pid, bytestream_id: bytestream_id }
	}
	let(:params) {
		ActionController::Parameters.new(permitted_params).permit!
	}
	let(:request_headers) { Hash.new }
	let(:request_double) { instance_double('ActionDispatch::Request', headers: request_headers) }
	let(:current_ability) { instance_double(Ability) }

	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:current_ability).and_return(current_ability)
		allow(controller).to receive(:fetch).and_return([nil, SolrDocument.new(solr_doc)])
		allow(controller).to receive(:bytestream_content_url).and_return("/")
	end

	context "making informational requests" do
		let(:content_length) { 11082 }
		let(:content_type) { "image/tiff" }
		let(:content_disposition) { "inline; filename*=utf-8''content.tiff" }
		before do
			allow(current_ability).to receive(:can?).and_return(true)
			allow(controller).to receive(:datastream_content_length).and_return content_length
			allow(controller).to receive(:document_content_type).and_return content_type
			allow(controller).to receive(:document_content_disposition).and_return content_disposition
		end
		describe '#content_head' do
			let(:response_double) { instance_double('ActionDispatch::Response', headers: response_headers) }
			let(:response_headers) { Hash.new }
			before do
				allow(controller).to receive(:expires_in)
				allow(controller).to receive(:response).and_return(response_double)
			end
			let(:expected_headers) do
				{
					"Accept-Ranges"=>"bytes",
					"Content-Disposition"=>content_disposition,
					"Content-Length"=>content_length,
					"Last-Modified"=>"Tue, 05 May 2015 15:14:53 GMT",
					:content_type=>content_type
				}
			end
			it "returns headers" do
				expect(controller).to receive(:head).with(200, hash_including(expected_headers))
				controller.content_head
			end
		end
		describe '#content_options' do
			let(:expected_headers) do
				{
					"Allow"=>"OPTIONS, GET, HEAD",
					"Accept-Ranges"=>"bytes"
				}
			end
			it "returns headers" do
				expect(controller).to receive(:options).with(204, hash_including(expected_headers))
				controller.content_options
			end
		end
	end
	describe '#content' do
		let(:response_double) { instance_double('ActionDispatch::Response', headers: response_headers) }
		let(:response_headers) { Hash.new }
		let(:expected_redirect) { "/repository_download/localhost:9080/fedora/objects/#{fedora_pid}/datastreams/#{bytestream_id}/content" }
		before do
			allow(controller).to receive(:expires_in)
			allow(controller).to receive(:response).and_return(response_double)
			allow(controller).to receive(:render).with(body: nil)
			allow(current_ability).to receive(:can?).and_return(true)
		end
		it "sets internal proxy headers" do
			controller.content
			expect(response_headers).to include('X-Accel-Redirect' => expected_redirect)
		end
	end
	describe "#object_profile" do
		let(:ds_parms) { nil }
		before do
			controller.instance_variable_set(:@document, SolrDocument.new(solr_doc))
		end
		it "supports ds MIME inspection" do
			expect(controller.document_content_type).to eql("image/tiff")
		end
		it "supports ds SIZE inspection" do
			expect(controller.datastream_content_length(ds_parms)).to eql(11082)
		end
		context 'with a labelled bytestream' do
			let(:bytestream_id) { 'thumbnail' }			
			let(:permitted_params) {
				{ catalog_id: fedora_pid, bytestream_id: bytestream_id, download: 'true' }
			}
			it "supports ds MIME inspection" do
				expect(controller.document_bytestream_filename).to eql("CCITT_2.jpg")
			end
			it "supports content Content-Disposition" do |variable|
				expect(controller.document_content_disposition).to eql("attachment; filename*=utf-8''CCITT_2.jpg")
			end
		end
	end
end
