require 'rails_helper'

describe Iiif::AccessController, type: :feature do
  describe "login" do
    let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }

    before do
      Warden.test_mode!
      login_as authorized_user, scope: :user
      visit "/iiif/3/login"
    end

    after do
      Warden.test_reset!
    end

    it "shows the success message" do
      expect(page).to have_text('Authentication successful!')
    end
  end
end
