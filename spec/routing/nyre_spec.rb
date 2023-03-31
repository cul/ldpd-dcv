require 'rails_helper'

describe NyreController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/nyre/search").to route_to(controller: "nyre", action:"index")
    end
  end
end
