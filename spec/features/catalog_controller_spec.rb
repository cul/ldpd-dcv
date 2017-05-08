require 'rails_helper'

describe CatalogController, type: :feature do
  describe "index" do
    before { visit catalog_index_path }
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
