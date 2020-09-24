require 'rails_helper'

describe Dcv::Sites::Import::Directory do
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { described_class.new(source) }
	let(:site) { import.run }
	describe '#run' do
		it 'sets properties' do
			expect(site.slug).to eql('import_site')
			expect(site.palette).to eql('parchment')
		end
		it 'imports links' do
			expect(site.nav_links.length).to eql(4)
		end
		it 'imports pages' do
			expect(site.site_pages.length).to eql(2)
		end
		it 'imports images' do
			signature_path = File.join(Rails.root, 'public', 'images', 'sites', site.slug, 'signature.svg')
			expect(File.exist?(signature_path)).to be true
		end
	end
end