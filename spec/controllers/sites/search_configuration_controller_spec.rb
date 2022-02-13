require 'rails_helper'

describe Sites::SearchConfigurationController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
			site_slug: site.slug
		)
	}
	let(:site) { FactoryBot.create(:site) }
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
	describe '#update' do
		let(:configuration_fixture) { YAML.load(fixture("yml/sites/search_configuration.yml").read).freeze }
		let(:rails_param_hash) do
			rph = configuration_fixture.map do |k, v|
				if v.is_a? Array
					[k, v.map.with_index {|c, i| [i.to_s, c]}.to_h]
				else
					[k, v.dup]
				end
			end.to_h
			# the form params have a composite param for field_name + pivot
			rph['facets'].each do |fc_tuple|
				fc = fc_tuple[1]
				fc['facet_fields_form_value'] = fc.delete('field_name') if fc['field_name']
			end
			rph
		end
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site.slug,
				site: { search_configuration: rails_param_hash }
			)
		}
		let(:edit_site_search_configuration_path) { "/#{site.slug}/search_configuration/edit" }
		before do
			allow(controller).to receive(:authorize_site_update).and_return(true)
			expect(controller).to receive(:edit_site_search_configuration_path)
			  .with(site_slug: site.slug).and_return(edit_site_search_configuration_path)
			expect(controller).to receive(:redirect_to).with(edit_site_search_configuration_path)
		end
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it do
				controller.update
				expected = Site::SearchConfiguration.new(configuration_fixture).as_json
				site.reload.search_configuration.as_json.each do |k, v|
					expect(v).to be_eql(expected[k])
				end
				expect(site.reload.search_configuration.as_json).to be_eql(Site::SearchConfiguration.new(configuration_fixture).as_json)
				expect(site.reload.search_configuration.as_json).not_to be_eql(Site::SearchConfiguration.new.as_json)
			end
		end
	end
end
