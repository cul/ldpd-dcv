require 'rails_helper'

describe CarnegieController, type: :routing do
  describe "routing" do
    it "routes to about page" do
      expect(carnegie_page_path('about', anchor: 'about_the_centennial')).to eql("/carnegie/about#about_the_centennial")
    end
  end
end
