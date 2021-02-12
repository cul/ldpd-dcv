require 'rails_helper'

describe ::Sites::ScopeFiltersController, type: :feature do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:site_layout) { import.atts['layout'] }
	let(:site_link_href) { "/#{site_slug}" }
	let(:edit_link_href) { "/#{site_slug}/scope_filters/edit" }
	describe '#update', js: true do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates atts' do
			click_button "Add Scope Filter"
			add_block = page.find('#scope_filters_1_atts')
			add_block.select("project", from: "site[scope_filters_attributes][1][filter_type]")
			add_block.fill_in('site[scope_filters_attributes][1][value]', with: "Test Project")
			click_button "Update Scope"
			# do a find to make sure page loaded
			find('#site_scope_filters_attributes_0_value')
			visit(edit_link_href)
			expect(find_field('site[scope_filters_attributes][1][value]').value).to eq("Test Project")			
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
		it "includes a link to view the site" do
			expect(page).to have_link('View Site', href: site_link_href)
		end
	end
end