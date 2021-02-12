require 'rails_helper'

describe Sites::ScopeFiltersController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) do
		ActionController::Parameters.new(
			site_slug: site.slug
		)
	end
	let(:site) { FactoryBot.create(:site, scope_filters: []) }
	let(:request_double) { instance_double('ActionDispatch::Request') }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
		controller.instance_variable_set(:@subsite, site)
	end
	describe '#scope_filter_params' do
		let(:attributes) { [] }
		let(:attributes_param) do
			attributes.inject({}) {|m,a| m[m.length.to_s] = a; m }
		end
		let(:params) do
			ActionController::Parameters.new(
				site: {
					empty: '',
					scope_filters_attributes: attributes_param
				}
			)
		end
		let(:update_params) { controller.send :scope_filter_params }
		before do
			controller.instance_variable_set(:@subsite, site)
		end
		it 'removes placeholders' do
			expect(update_params['empty']).to be_nil
		end

		context 'with attributes' do
			let(:attributes) { [{filter_type: 'project_key', value: 'test_project'}] }
			context 'that are empty' do
				let(:attributes) { [] }
				it "parses the value array" do
					expect(update_params[:scope_filters_attributes]).to be_empty
				end
			end
		end
		context 'without attributes' do
			let(:params) do
				ActionController::Parameters.new(
					site: { empty: '' }
				)
			end
			it 'has nil attributes' do
				expect(update_params['scope_filters_attributes']).to be_nil
			end
			it 'removes placeholders' do
				expect(update_params['empty']).to be_nil
			end
		end
	end
	describe '#update' do
		let(:scope_filters_fixture) { YAML.load(fixture("yml/sites/scope_filters.yml").read).freeze }
		let(:rails_param_hash) do
			scope_filters_fixture
		end
		let(:params) do
			ActionController::Parameters.new(
				site_slug: site.slug,
				site: rails_param_hash
			)
		end
		let(:authorized) { true }
		before do
			allow(controller).to receive(:authorize_site_update).and_return(authorized)
			expect(controller).to receive(:redirect_to).with(action: :edit)
		end
		context 'data has additions' do
			before do
				atts = scope_filters_fixture['scope_filters_attributes']['0']
				site.scope_filters << ScopeFilter.new(atts)
				site.save
			end
			it do
				controller.update
				expect(controller.flash[:notice]).to eql('Scope Updated!')
				expected_filters = scope_filters_fixture['scope_filters_attributes']
				expect(site.reload.scope_filters.length).to eql(expected_filters.length)
			end
		end
		context 'data has deletions' do
			let(:remaining_atts) { scope_filters_fixture.dig('scope_filters_attributes', '1') }
			let(:rails_param_hash) do
				{
					'scope_filters_attributes' => {
						'1' => remaining_atts
					}
				}
			end
			before do
				scope_filters_fixture['scope_filters_attributes'].each do |k, atts|
					site.scope_filters << ScopeFilter.new(atts)
				end
				site.save
			end
			it do
				controller.update
				expect(controller.flash[:notice]).to eql('Scope Updated!')
				expect(site.reload.scope_filters.length).to eql(1)
				expect(site.scope_filters.first.filter_type).to eql(remaining_atts['filter_type'])
				expect(site.scope_filters.first.value).to eql(remaining_atts['value'])
			end
		end
		context 'data has replacements' do
			let(:remaining_atts) { scope_filters_fixture.dig('scope_filters_attributes', '1') }
			let(:replacement_atts) { {'filter_type' => 'repository_code', 'value' => 'NNC'} }
			let(:rails_param_hash) do
				{
					'scope_filters_attributes' => {
						'0' => replacement_atts,
						'1' => remaining_atts
					}
				}
			end
			before do
				scope_filters_fixture['scope_filters_attributes'].each do |k, atts|
					site.scope_filters << ScopeFilter.new(atts)
				end
				site.save
			end
			it do
				controller.update
				expect(controller.flash[:notice]).to eql('Scope Updated!')
				actual_scope_filters = site.reload.scope_filters
				expect(actual_scope_filters.length).to eql(2)
				expect(actual_scope_filters[0].filter_type).to eql(replacement_atts['filter_type'])
				expect(actual_scope_filters[0].value).to eql(replacement_atts['value'])
				expect(actual_scope_filters[1].filter_type).to eql(remaining_atts['filter_type'])
				expect(actual_scope_filters[1].value).to eql(remaining_atts['value'])
			end
		end
		context 'data is absent' do
			let(:params) do
				ActionController::Parameters.new(
					site: { empty: '' }
				)
			end
			before do
				scope_filters_fixture['scope_filters_attributes'].each do |k, atts|
					site.scope_filters << ScopeFilter.new(atts)
				end
				site.save
			end
			it do
				controller.update
				expect(controller.flash[:notice]).to eql('Scope Updated!')
				expect(site.reload.scope_filters.length).to eql(0)
			end
		end
	end
end
