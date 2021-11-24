require 'rails_helper'

describe Dcv::Sites::Import::Directory do
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { described_class.new(source) }
	let(:site) { import.run }
	describe '#run' do
		it 'sets properties' do
			expect(site.slug).to eql('import_site')
			expect(site.palette).to eql('blue')
		end
		it 'imports links' do
			expect(site.nav_links.length).to eql(4)
			expect(site.about_link&.sort_label).to eql('About')
		end
		it 'imports pages' do
			expect(site.site_pages.length).to eql(2)
		end
		it 'imports images' do
			signature_path = File.join(Rails.root, 'public', 'images', 'sites', site.slug, 'signature.svg')
			expect(File.exist?(signature_path)).to be true
		end
		it 'imports search configuration' do
			sc = site.search_configuration
			expect(sc.map_configuration.enabled).to be false
			expect(sc.date_search_configuration.enabled).to be true
			expect(sc.date_search_configuration.granularity_search).to eql 'year'
			expect(sc.facets.length).to be 1
			expect(sc.facets.first.field_name).to eql 'role_test_sim'
			expect(sc.search_fields.length).to be 2
			expect(sc.search_fields.map(&:type)).to eql ['keyword', 'fulltext']
			expect(sc.search_fields.map(&:label)).to eql ['Test Keyword', 'Test Text']
		end
		it 'imports scope filters' do
			expect(site.publisher_constraints).to eql(['info:fedora/cul:import_site'])
		end
		it 'imports permissions' do
			expect(site.permissions.remote_ids).to eql(['siteAdmin'])
		end
	end
end