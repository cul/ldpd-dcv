require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::HighlightedSnippetHelper. For example:
#
# describe Dcv::HighlightedSnippetHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe Dcv::HighlightedSnippetHelper, :type => :helper do
  
  describe "#render_snippet_with_post_processing" do
    it 'removes all html tags other than the opening and closing span highlight tags (i.e <span class="highlight"> and </span>)' do
      original_snippet = 'This <em>is</em> the <span class="highlight">term</span> that is being highlighted...The <span class="highlight">term</span> is appropriately highlighted thanks to this <strong>great</strong> highlighting.'
      expected_post_processed_snippet = 'This is the <span class="highlight">term</span> that is being highlighted...The <span class="highlight">term</span> is appropriately highlighted thanks to this great highlighting.'
      expect(helper.render_snippet_with_post_processing(original_snippet)).to eq(expected_post_processed_snippet)
    end
  end
  
end
