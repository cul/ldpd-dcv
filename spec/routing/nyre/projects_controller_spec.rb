require 'rails_helper'

describe Nyre::ProjectsController, :type => :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/nyre/projects/1234").to route_to(controller: "nyre/projects", action:"show", id: "1234")
    end
  end
end
