require 'rails_helper'

describe SitesController, type: :feature do
  let(:catalog_pid) { 'cul:vmcvdnck2d' }
  describe "show" do
    before do
      visit site_url('catalog')
    end
    it "should render the markdown description" do
      expect(page).to have_xpath('//li/a', text: 'Avery Architectural & Fine Arts Library')
    end
  end
end
