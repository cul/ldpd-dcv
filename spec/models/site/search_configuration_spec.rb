require 'rails_helper'
describe Site::SearchConfiguration do
	describe Site::SearchConfiguration::Type do
		it "initializes a Site::SearchConfiguration for new values" do
			site = Site.new
			expect(site.search_configuration).to be_a Site::SearchConfiguration
		end
		it "casts a new Site::SearchConfiguration from nil db value" do
			site = Site.instantiate('search_configuration' => nil)
			expect(site.search_configuration).to be_a Site::SearchConfiguration
		end
	end
end