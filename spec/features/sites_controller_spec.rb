require 'rails_helper'

describe SitesController, type: :feature, js: true do
  include_context "site fixtures for features"
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
  describe "home" do
    before do
      visit site_path('internal_site')
    end
    it "should render the markdown description" do
      expect(page).to have_xpath('/descendant::li/a', text: 'Avery Architectural & Fine Arts Library')
    end
  end
  describe "update" do
    let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
    before do
      Warden.test_mode!
      login_as authorized_user, scope: :user
      visit edit_site_path('internal_site')
      expect(current_path).to eql(edit_site_path('internal_site'))
      expect(page).to have_select('site_layout', selected: 'DLC Default')
      expect(page).to have_select('site_search_type', selected: 'Catalog')
      select('Gallery', from: 'site_layout')
      select('Local', from: 'site_search_type')
      click_button "Add Navigation Menu"
      # use IDs since template elements are hidden but ambiguous
      find('button[data-target="#site_navigation_links_0"]').click # Show Links
      find('#menu-0-add-link').click # Add Link
      find('#site_nav_menus_attributes_0_label').set("Group Label Value")
      find('#site_nav_menus_attributes_0_links_attributes_0_label').set("Link Label Value")
      find('#site_nav_menus_attributes_0_links_attributes_0_link').set("sitePage")
      find('#site_nav_menus_attributes_0_links_attributes_0_external_false').set(true)
      click_button "Update Site Information"
    end
    after do
      Warden.test_reset!
    end
    it "updates the values" do
      expect(current_path).to eql(edit_site_path('internal_site'))
      expect(page).to have_select('site_layout', selected: 'Gallery')
      expect(page).to have_select('site_search_type', selected: 'Local')
      find('button[data-parent="#site_navigation_menu_0"]').click # Show Links
      expect(page).to have_css("#site_nav_menus_attributes_0_label[value='Group Label Value']")
      expect(page).to have_css("#site_nav_menus_attributes_0_links_attributes_0_label[value='Link Label Value']")
    end
  end
end
