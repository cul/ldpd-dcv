require 'rails_helper'

describe CatalogController, type: :feature do
  include_context "site fixtures for features"
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
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
      expect(page).to have_text('No results found')
    end
  end
end
