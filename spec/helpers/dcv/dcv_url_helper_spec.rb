require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::DcvUrlHelper. For example:
#
# describe Dcv::DcvUrlHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe Dcv::DcvUrlHelper, :type => :helper do
  describe '#site_edit_link' do
    let(:site) { FactoryBot.create(:site) }
    let(:can) { true }
    before do
      assign(:subsite, site)
      allow(helper).to receive(:can?).and_return can
    end
    context 'when not authorized' do
      let(:can) { false }
      it 'is nil' do
        expect(helper.site_edit_link).to be_nil
      end
    end
    context 'when not on a page' do
      it 'links to site edit' do
        expect(helper).to receive(:edit_site_path).with(slug: site.slug).and_return("link")
        helper.site_edit_link
      end
    end
    context 'when on a page' do
      let(:page) { FactoryBot.create(:site_page) }
      before do
        assign(:page, page)
      end
      pending 'revisit with solution to rspec issue of page instance variable'
    end
  end
end
