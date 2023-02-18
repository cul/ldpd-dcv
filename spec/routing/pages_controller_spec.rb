require 'rails_helper'

describe PagesController, :type => :routing do
  let(:fake_doi) { "10.7916/fake-doi" }
  describe "routing" do
    it "routes to #tombstone" do
      expect(:get => "/tombstone/#{fake_doi}").to route_to(controller: "pages", action:"tombstone", id: fake_doi)
    end
  end
  describe "url_helpers" do
    it do
      expect(tombstone_doi_path(fake_doi)).to eql("/tombstone/#{fake_doi}")
    end
  end
end
