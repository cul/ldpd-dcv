require 'rails_helper'

describe CatalogController, type: :feature do
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
  include_context "site fixtures for features"
  # show does not verify item scope, so any item will do here
  describe "index" do
    before { visit search_catalog_path }
    it "shows the 'Perform a search' message when you visit the catalog index without any search parameters" do
      expect(page).to have_text('Perform a search')
    end

    it "shows concepts when performing a search with a relevant query" do
      find(:xpath, '//div[@id="search-navbar"]//input[@id="q"]').set('Internal')
      find(:xpath, '//div[@id="search-navbar"]//button').click
      expect(page).to have_text('Internal Library Project')
    end

    it "shows no concepts when performing a search with no query" do
      find(:xpath, '//div[@id="search-navbar"]//button').click
      expect(page).not_to have_css('.site-result')
    end
  end
  describe "show" do
    before { visit "/catalog/donotuse:item" }
    it "shows the item title" do
      expect(page).to have_text('William Burroughs')
    end
  end
  describe "home" do
    before do
      visit root_path
    end
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
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/catalog']")
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/sites']")
    end
  end
end
