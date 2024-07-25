require 'rails_helper'

describe ::Sites::SearchConfigurationController, type: :feature do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:site_layout) { import.atts['layout'] }
	let(:site_link_href) { "/#{site_slug}" }
	let(:edit_link_href) { "/#{site_slug}/search_configuration/edit" }
	describe '#update', js: true do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates map atts' do
			fill_in('Default Latitude', with: "42.0")
			fill_in('Default Longitude', with: "24.0")
			click_button "Update Search Configuration"
			# do a find to make sure page loaded
			find('#site_search_configuration_map_configuration_default_lat')
			visit(edit_link_href)
			expect(page).to have_field('Default Latitude', with: "42.0")			
			expect(page).to have_field('Default Longitude', with: "24.0")			
		end
		it 'updates facet atts' do
			expect(find_field('site[search_configuration][facets][0][facet_fields_form_value]').value).to eq("role_test_sim")
			click_button "Add a facet field"
			add_block = page.find('#facet_fields_1_atts')
			add_block.fill_in('site[search_configuration][facets][1][facet_fields_form_value]', with: "level_one_field_sim,level_2_field_sim")
			add_block.fill_in('site[search_configuration][facets][1][label]', with: "Levels")
			click_button "Update Search Configuration"
			# do a find to make sure page loaded
			find('#facet_fields_1_atts')
			visit(edit_link_href)
			expect(find_field('site[search_configuration][facets][1][facet_fields_form_value]').value).to eq("level_one_field_sim,level_2_field_sim")
			expect(find_field('site[search_configuration][facets][1][label]').value).to eq("Levels")
		end
		it 'updates grid display field configuration' do
			# verify the initial value from the import
			expect(find_field('site[search_configuration][display_options][grid_field_types]').value).to eq("project, name")
			page.fill_in('site[search_configuration][display_options][grid_field_types]', with: 'format, project')			
			click_button "Update Search Configuration"
			# do a find to make sure page loaded
			find('#site_search_configuration_display_options_grid_field_types')
			visit(edit_link_href)
			# verify the value update
			expect(find_field('site[search_configuration][display_options][grid_field_types]').value).to eq("format, project")			
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