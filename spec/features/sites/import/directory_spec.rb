require 'rails_helper'

describe Dcv::Sites::Import::Directory do
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { described_class.new(source) }
	let(:site) { import.run }
	describe '#run' do
		it 'sets properties' do
			expect(site.slug).to eql('import_site')
			expect(site.palette).to eql('blue')
			expect(site.show_facets).to be true
		end
		it 'imports links' do
			expect(site.nav_links.length).to eql(4)
			expect(site.about_link&.sort_label).to eql('About')
		end
		it 'imports pages' do
			expect(site.site_pages.length).to eql(2)
			about_page = site.site_pages.where(slug: 'about').first
			page_image = about_page.site_page_images.first
			expect(page_image.caption).to eql('Photograph of welder, Empire State Building')
			text_block = about_page.site_text_blocks.sort_by(&:sort_label)[1]
			expect(text_block.markdown).to include("Rails philosophy")
			block_image = text_block.site_page_images.first
			expect(block_image.caption).to eql('Blue Nursery')
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