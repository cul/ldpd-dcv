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
end
