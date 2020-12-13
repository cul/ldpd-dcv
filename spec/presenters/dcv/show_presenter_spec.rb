require 'rails_helper'

describe Dcv::ShowPresenter do
    include_context "a solr document"
	let(:types) { ['Type 1', 'Type 2', 'Type 3'] }
	let(:search_state) { instance_double(Blacklight::SearchState) }
	let(:view_context) { double(ActionController::Base) }
	let(:options) { {} }
	let(:controller_name) { 'some_controller' }
	let(:format) { 'xml' }
	let(:show_params) { {controller: controller_name, action: 'show', id: document_id, format: format} }
	let(:presenter) { described_class.new(solr_document, view_context, options) }
	before do
		allow(view_context).to receive(:search_state) { search_state }
		# allow(search_state).to receive(:url_for_document).with(solr_document) { show_params }
	end
	describe "#field_values" do
		subject { presenter.field_values(field_config) }
		context 'for a single value field' do
			let(:field_config) {
				Blacklight::Configuration::Field.new({
					field_name: 'id',
					label: 'Test Field'
				})
			}
			it 'returns a single value' do
				is_expected.to be_a String
			end
		end
		context 'for a multiple value field' do
			context 'that is configured not to be joined' do
				let(:field_config) {
					Blacklight::Configuration::Field.new({
						field: 'dc_type_ssm',
						label: 'Test Field',
						join: false
					})
				}
				it 'returns multiple values' do
					is_expected.to be_a Array
					is_expected.to satisfy {|x| x.length == 3}
				end
			end
			context 'that is configured to be joined' do
				let(:field_config) {
					Blacklight::Configuration::Field.new({
						field: 'dc_type_ssm',
						label: 'Test Field',
						join: true
					})
				}
				it 'returns a single value' do
					is_expected.to be_a String
					is_expected.to include *types
				end
			end
			context 'that has no join configuration' do
				let(:field_config) {
					Blacklight::Configuration::Field.new({
						field: 'dc_type_ssm',
						label: 'Test Field'
					})
				}
				it 'returns a single value' do
					is_expected.to be_a String
					is_expected.to include *types
				end
			end
		end
	end
end