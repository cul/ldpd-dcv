require 'rails_helper'

describe ::Sites::SearchConfigurationController, type: :feature do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:site_layout) { import.atts['layout'] }
	let(:site_link_href) { "/#{site_slug}" }
	let(:edit_link_href) { "/#{site_slug}/search_configuration/edit" }
	describe '#update' do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates atts' do
			fill_in('Default Latitude', with: "42.0")
			fill_in('Default Longitude', with: "24.0")
			click_button "Update Search Configuration"
			# do a find to make sure page loaded
			find('#site_search_configuration_map_configuration_default_lat')
			visit(edit_link_href)
			expect(page).to have_field('Default Latitude', with: "42.0")			
			expect(page).to have_field('Default Longitude', with: "24.0")			
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