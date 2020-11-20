require 'rails_helper'

describe SitesController, type: :feature do
  include_context "site fixtures for features"
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
  describe "home" do
    before do
      visit site_url('internal_site')
    end
    it "should render the markdown description" do
      expect(page).to have_xpath('/descendant::li/a', text: 'Avery Architectural & Fine Arts Library')
    end
  end
  describe "update", js: true do
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
      #click_button 'Add Link'
      find('button[data-parent=site_navigation_menu_0]').click # Show Links
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
      find('button[data-parent=site_navigation_menu_0]').click # Show Links
      expect(page).to have_css("#site_nav_menus_attributes_0_label[value='Group Label Value']")
      expect(page).to have_css("#site_nav_menus_attributes_0_links_attributes_0_label[value='Link Label Value']")
    end
  end
  describe "index" do
    before { visit root_url }
    it "links to tabs and has external digital collections link" do
      expect(page).to have_xpath("/descendant::a[@href='#projects' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_name_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_format_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_repo_long_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@title='See All Digital Collections']")
    end
    context 'in the projects div' do
      it "links to internal_site" do
        expect(page).to have_xpath("//div[@id='projects']")
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='#{site_url('internal_site')}' and @itemprop='url']")
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@itemprop='name']", text: 'Internal Library Project Online')
      end
      it "does not link to external_site" do
        expect(page).not_to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='https://external.library.columbia.edu' and @itemprop='url']")
        expect(page).not_to have_xpath("//div[@id='projects']/descendant::div[@itemprop='name']", text: 'External Library Project Online')
      end
      it "links to internal_site content with facet value" do
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='/catalog?f%5Blib_project_short_ssim%5D%5B%5D=Internal+Project' and @title='Browse Content']")
      end
    end
    it "doesn't link to external_site content with facet value" do
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/catalog?f%5Blib_project_short_ssim%5D%5B%5D=External+Project']")
    end
    it "doesn't link to catalog, sites" do
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/sites/catalog']")
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/sites/sites']")
    end
  end
end
