require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::CdnHelper. For example:
#
# describe Dcv::CdnHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe ShowFieldDisplayFieldHelper, :type => :helper do
  describe '#link_to_repo_homepage' do
  	it "should use long label when available" do
      link = helper.link_to_repo_homepage("Avery Library")
      expect(link).to match("Architectural")
      expect(link).to match("avery.html")
  	end
    it "should not link if no url translation" do
      link = helper.link_to_repo_homepage("Non-Columbia Location")
      expect(link).to be_nil
    end
  end
end