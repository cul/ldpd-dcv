require 'rails_helper'

describe ::Sites::PagesController, type: :feature do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:site_layout) { import.atts['layout'] }
	let(:page_link) { "/#{site_slug}/about" }
	let(:edit_link_href) { "#{page_link}/edit" }
	describe '#show' do
		before do
			import.atts['layout'] = site_layout
			import.run
		end
		shared_context "displays expected text" do
			it 'displays expected text' do
				visit(page_link)
				expect(page).to have_css('li > strong', text: 'Don\'t Repeat Yourself')
			end
		end
		Dcv::Sites::Constants::VALID_LAYOUTS.each do |valid_layout|
			context "in \"#{valid_layout}\" layout" do
				let(:site_layout) { valid_layout }
				include_context "displays expected text"
			end
		end
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
	describe 'text block updates' do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates text blocks' do
			find('button[data-parent=site_text_block_0]').click # Show Text Block content
			new_text = find('#site_page_site_text_blocks_attributes_0_markdown').value
			new_text.sub!('Don\'t Repeat Yourself', "Text Block Value")
			# the markdown textarea is display:none by the editor widget, but we're not running js
			find('#site_page_site_text_blocks_attributes_0_markdown').set(new_text)
			click_button "Update Page"
			# do a find to make sure page loaded
			find('#site_page_site_text_blocks_attributes_0_markdown')
			visit(page_link)
			expect(page).to have_xpath("//strong", text: "Text Block Value")			
		end
	end
	describe 'text block addition and removal', js: true do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates text blocks' do
			find('#site-page-add-block').click
			find('button[data-parent=site_text_block_1]').click # Show Text Block content
			find('#site_page_site_text_blocks_attributes_1_label').set("Text Block Value")
			# sending key events is complicated; we will fake it with the editor's JS api
			page.execute_script("document.querySelector('#site_page_text_block_1_markdown .CodeMirror').CodeMirror.setValue('**Text Block Value**');")
			# remove the first block - the second should be all that is left
			find('#site_text_block_0 .remove').click
			click_button "Update Page"
			# do a find to make sure page loaded
			find('button[data-parent=site_text_block_0]').click # Show Text Block content
			expect(find('#site_page_site_text_blocks_attributes_0_markdown', visible: :any).value).to include('Text Block Value')
			visit(page_link)
			expect(page).to have_xpath("//strong", text: "Text Block Value")
			expect(page).to have_xpath("//h3", text: 'Text Block Value')			
			expect(page).not_to have_xpath("//h3", text: 'About')			
		end
	end
	describe '#create', js: true do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		let(:new_page_slug) { 'new_page' }
		let(:new_page_title) { 'Brand New Page' }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit("/#{site_slug}/pages/new")
		end
		it 'updates text blocks' do
			find('#site-page-add-block').click
			find('button[data-parent=site_text_block_0]').click # Show Text Block content
			find('#site_page_slug').set(new_page_slug)
			find('#site_page_title').set(new_page_title)
			find('#site_page_site_text_blocks_attributes_0_label').set("Text Block Value")
			# sending key events is complicated; we will fake it with the editor's JS api
			page.execute_script("document.querySelector('#site_page_text_block_0_markdown .CodeMirror').CodeMirror.setValue('**Text Block Value**');")
			click_button "Create Page"
			# do a find to make sure page loaded
			find('button[data-parent=site_text_block_0]').click # Show Text Block content
			expect(find('#site_page_site_text_blocks_attributes_0_markdown', visible: :any).value).to include('Text Block Value')
			visit("#{site_slug}/#{new_page_slug}")
			expect(page).to have_xpath("//h2", text: new_page_title)
			expect(page).to have_xpath("//strong", text: "Text Block Value")
			expect(page).to have_xpath("//h3", text: 'Text Block Value')
		end
	end
	describe '#edit' do
		before do
			import.run
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		it "includes a link to view the page" do
			within('h1') do
				expect(page).to have_link('view', href: page_link)
			end
		end
		context "home page" do
			let(:edit_link_href) { "/#{site_slug}/home/edit" }
			it "links to the site path to view the page" do
				within('h1') do
					expect(page).to have_link('view', href: "/#{site_slug}")
				end
			end
		end
	end
end