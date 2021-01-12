require 'rails_helper'

describe JayController, type: :feature do
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
  include_context "site fixtures for features"
  # show does not verify item scope, so any item will do here
  describe "show" do
    before { visit "/jay/donotuse:item" }
    it "shows the item title" do
      expect(page).to have_text('William Burroughs')
    end
  end
end
