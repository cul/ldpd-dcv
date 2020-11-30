require 'rails_helper'

describe ::Sites::PagesController do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:page_link) { "/#{site_slug}/about" }
	let(:edit_link_href) { "#{page_link}/edit" }
	describe '#show' do
		before { import.run }
		it 'displays expected text' do
			visit(page_link)
			expect(page).to have_css('li > strong', text: 'Don\'t Repeat Yourself')
		end
		it 'links to scoped search' do
			visit(page_link)
			# <input type="hidden" name="f[publisher_ssim][]" value="info:fedora/cul:import_site">
			expect(page).to have_xpath("//input[@type='hidden' and @name='f[publisher_ssim][]' and @value='info:fedora/cul:import_site']", visible: :any)
		end
		it 'does not link to page edit' do
			visit(page_link)
			expect(page).not_to have_xpath("//a[@href='#{edit_link_href}']", visible: :any)			
		end
		context 'editor is logged in' do
			let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
			before do
				Warden.test_mode!
				login_as authorized_user, scope: :user
			end
			it 'links to edit for this page' do
				visit(page_link)
				expect(page).to have_xpath("//a[@href='#{edit_link_href}']", visible: :any)			
			end
		end
	end
end