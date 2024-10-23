require 'rails_helper'

describe DetailsController, type: :feature do
  # the relevant fixtures are loaded into the repository and seeded into the Site
  # database tables by CI tasks
  include_context "site fixtures for features"

  describe "details" do
    before { visit "/catalog/donotuse:item/details" }
    it "shows the item title" do
      expect(page).to have_text('William Burroughs')
    end
  end
  describe "embed" do
    before { visit "/catalog/10.99999/1234-donotuse-item/embed" }
    it "shows the no assets message" do
      expect(page).to have_text('The zoomable version of this image is not yet available.')
    end
  end
end
