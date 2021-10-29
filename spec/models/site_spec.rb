require 'rails_helper'
describe Site do
	let(:site) { FactoryBot.create(:site, slug: site_slug) }
	describe '#initialize' do
		let(:site_slug) { 'initialize' }
		it 'defaults search type to catalog' do
			expect(Site.new.search_type).to eql('catalog')
		end
	end
	describe '#nav_menus' do
		let(:site_slug) { 'grouped_links' }
		let(:site) { FactoryBot.create(:site_with_links, slug: site_slug) }
		let(:unlabeled_menu) { site.nav_menus.detect { |nm| nm.sort_label.nil? } }
		let(:labeled_menu) { site.nav_menus.detect { |nm| !nm.sort_label.nil? } }
		it 'groups links according to sort group' do
			expect(labeled_menu.label).to eql('Project History')
			expect(labeled_menu.length).to eql(2)
			expect(unlabeled_menu.label).to be_blank
			expect(unlabeled_menu.length).to eql(1)
		end
	end
	describe 'constraints' do
		let(:site_slug) { 'constraints' }
		let(:values) { [ 'constraints_value_1' ] }
		let(:scope_filters) { values.map { |value| ScopeFilter.new(filter_type: filter_type, value: value) } }
		let(:site) { FactoryBot.create(:site, slug: site_slug, scope_filters: scope_filters) }
		context 'on collection' do
			let(:filter_type) { 'collection' }
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('collection' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('lib_collection_sim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("lib_collection_sim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("lib_collection_sim:(\"#{values.first}\")")
			end
		end
		context 'on collection key' do
			let(:filter_type) { 'collection_key' }
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('collection_key' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('collection_key_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("collection_key_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("collection_key_ssim:(\"#{values.first}\")")
			end
		end
		context 'on project' do
			let(:filter_type) { 'project' }
			it 'adds a project clause to the constraints hash' do
				expect(site.constraints).to include('project' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('lib_project_short_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("lib_project_short_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("lib_project_short_ssim:(\"#{values.first}\")")
			end
		end
		context 'on project key' do
			let(:filter_type) { 'project_key' }
			it 'adds a project_key clause to the constraints hash' do
				expect(site.constraints).to include('project_key' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('project_key_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("project_key_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("project_key_ssim:(\"#{values.first}\")")
			end
		end
		context 'on publisher' do
			let(:filter_type) { 'publisher' }
			it 'adds a publisher clause to the constraints hash' do
				expect(site.constraints).to include('publisher' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('publisher_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("publisher_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("publisher_ssim:(\"#{values.first}\")")
			end
		end
	end
	describe 'editor_uids' do
		let(:site_slug) { 'editor_uids' }
		describe '#editor_uids' do
			it 'returns an array' do
				expect(site.editor_uids).to be_a Array
			end
		end
		describe '#editor_uids=' do
			let(:original_value) { "fake1" }
			let(:additional_value) { "fake2" }
			it 'accepts an array' do
				site.editor_uids << original_value
				site.save
				expect(site.editor_uids.length).to be 1
				site.editor_uids = [original_value, additional_value]
				site.save
				expect(site.editor_uids.length).to be 2
				expect(site.editor_uids).to eql [original_value, additional_value]
			end
			it 'rejects a string' do
				expect { site.editor_uids = additional_value }.to raise_error
			end
		end
	end
	describe 'image uri methods' do
		let(:site_slug) { 'image_uris' }
		describe '#image_uris' do
			it 'returns an array' do
				expect(site.image_uris).to be_a Array
			end
		end
		describe '#image_uris=' do
			let(:additional_value) { "info:fedora/fake:1" }
			it 'accepts an array' do
				site.image_uris << additional_value
				site.save
				expect(site.image_uris.length).to be 2
				site.image_uris = [additional_value]
				site.save
				expect(site.image_uris.length).to be 1
				expect(site.image_uri).to eql additional_value
			end
			it 'rejects a string' do
				expect { site.image_uris = additional_value }.to raise_error
			end
		end
		describe '#image_uri' do
			it 'returns a single uri selected from an array' do
				expect(site.image_uri).to be_a String
			end
		end
	end
	describe '#to_subsite_config' do
		let(:site_slug) { 'to_subsite_config' }
		let(:subject) { site.to_subsite_config }
		it "converts to a hash" do
			is_expected.to be_a Hash
			expect(subject[:slug]).to eql site_slug
			expect(subject[:restricted]).not_to be
			expect(subject[:palette]).to eql 'monochromeDark'
		end
	end
	describe '#routing_params' do
		let(:site_slug) { 'routing_params' }
		let(:args) { { slug: site_slug } }
		let(:subject) { site.routing_params(args) }
		before do
			site.configure_blacklight!
		end
		context 'configured with a custom search' do
			let(:site) { FactoryBot.create(:site, slug: site_slug, search_type: 'custom') }
			it "assigns appropriate controller routing" do
				is_expected.to be_a Hash
				is_expected.not_to have_key(:slug)
				is_expected.to include(controller: "/#{site_slug}")
			end
		end
		context 'configured with a local search' do
			let(:site) { FactoryBot.create(:site, slug: site_slug, search_type: 'local') }
			it "assigns appropriate controller routing" do
				is_expected.to be_a Hash
				is_expected.not_to have_key(:slug)
				is_expected.to include(controller: "/sites/search", site_slug: site_slug)
			end
		end
		it "assigns appropriate controller routing" do
			is_expected.to be_a Hash
			is_expected.not_to have_key(:slug)
			is_expected.to include(controller: "/catalog")
		end
	end
	describe '#configure_blacklight!' do
		let(:site_slug) { 'configure_blacklight' }
		let(:search_configuration) { YAML.load(fixture("yml/sites/search_configuration.yml").read) }
		let(:publisher_filter) { FactoryBot.create(:scope_filter, filter_type: 'publisher', value: 'info:fedora/cul:import_site') }
		let(:site) { FactoryBot.create(:site, slug: site_slug, search_type: 'local', search_configuration: search_configuration, scope_filters: [publisher_filter]) }
		before do
			site.configure_blacklight!
		end
		it 'sets facet configurations' do
			expect(site.blacklight_config.facet_fields.keys).to eql(['role_test_sim'])
		end
		context 'with map_configuration.enabled' do
			let(:search_configuration) do
				base = YAML.load(fixture("yml/sites/search_configuration.yml").read)
				base['map_configuration']['enabled'] = true
				base
			end
			it 'sets facet configurations' do
				expect(site.blacklight_config.facet_fields.keys.sort).to eql(['has_geo_bsi', 'role_test_sim'])
			end
		end
		context 'without search_configuration' do
			let(:site) { FactoryBot.create(:site, slug: site_slug, search_type: 'local') }
			it 'uses default catalog configurations' do
				expect(site.blacklight_config.facet_fields.length).to be > 1
			end
		end
	end
end