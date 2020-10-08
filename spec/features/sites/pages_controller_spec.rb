require 'rails_helper'

describe ::Sites::PagesController do
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site) { import.run }
	describe '#show' do
		it 'displays expected text' do
			visit("/#{site.slug}/about")
			expect(page).to have_css('li > strong', text: 'Don\'t Repeat Yourself')
		end
		it 'links to scoped search' do
			visit("/#{site.slug}/about")
			# <input type="hidden" name="f[publisher_ssim][]" value="info:fedora/cul:import_site">
			expect(page).to have_xpath("//input[@type='hidden' and @name='f[publisher_ssim][]' and @value='info:fedora/cul:import_site']")
		end
	end
end