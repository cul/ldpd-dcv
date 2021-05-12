require 'rails_helper'

describe Resolve::DoisController, :type => :routing do
  describe "routing" do
    it "routes to #resolve" do
      expect(:get => "/resolve/10.3455/12345-abcd").to route_to(controller: "resolve/dois", action:"resolve", registrant:"10.3455", doi: "12345-abcd", format: "json")
      expect(:get => "/resolve/11.3455/12345-abcd").not_to route_to(controller: "resolve/dois", action:"resolve", registrant:"10.3455", doi: "12345-abcd", format: "json")
    end
  end
  describe "url_helpers" do
    it 'produces resolver paths' do
      expect(resolve_doi_path(registrant:"10.3455", doi: "12345-abcd")).to eql("/resolve/10.3455/12345-abcd")
    end
  end
end
