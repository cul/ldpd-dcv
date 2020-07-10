require 'rails_helper'

describe Dcv::LinkAlternatePresenter do
    include_context "a solr document"
	let(:search_state) { instance_double(Blacklight::SearchState) }
	let(:view_context) { double(ActionController::Base) }
	let(:options) { {} }
	let(:controller_name) { 'some_controller' }
	let(:format) { 'xml' }
	let(:show_params) { {controller: controller_name, action: 'show', id: document_id, format: format} }
	let(:presenter) { described_class.new(view_context, solr_document, options) }
	before do
		allow(view_context).to receive(:search_state) { search_state }
		allow(search_state).to receive(:url_for_document).with(solr_document) { show_params }
	end
	describe "href" do
		before do
			expect(view_context).to receive(:url_for).with(href_params)
		end
		context 'not a site document' do
			let(:href_params) { show_params }
			it 'links to current search state' do
				presenter.href(format)
			end
		end
		context 'site document' do
			include_context "indexed from a site object"
			let(:href_params) { {controller: 'sites', slug: slug, action: 'home', format: format} }
			it 'links to sites' do
				presenter.href(format)
			end
		end
	end
end