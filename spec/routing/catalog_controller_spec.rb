require 'rails_helper'

describe CatalogController, :type => :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/").to route_to(controller: "catalog", action:"home")
    end
  end
end
