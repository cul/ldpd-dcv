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

describe Dcv::SubsiteHelper, :type => :helper do
	#let(:controller) { instance_double(SitesController) }
	let(:site_slug) { 'siteSlug' }
	let(:nav_link) { NavLink.new(link: link, external: external, sort_label: sort_label) }
	let(:sort_label) { '00:Link Label' }
	before do
		allow(controller).to receive(:subsite_config).and_return(slug: site_slug)
		#allow(helper).to receive(:controller).and_return(controller)
	end
	describe "#link_to_nav" do
		context 'site page by slug' do
			let(:external) { false }
			let(:link) { 'slug' }
			let(:expected_path) { '/siteSlug/slug' }
			it "links to site_page" do
				expect(helper).to receive(:site_page_path).with(site_slug: site_slug, slug: link).and_return(expected_path)
				helper.link_to_nav(nav_link)
			end
			context 'with an anchor' do
				let(:link) { 'slug#anchor' }
				it "links to site_page with anchor" do
					expect(helper).to receive(:site_page_path).with(site_slug: site_slug, slug: 'slug', anchor: 'anchor').and_return(expected_path)
					helper.link_to_nav(nav_link)
				end
			end
		end
		context 'relative url' do
			let(:external) { true }
			let(:link) { "/link?foo=gee" }
			it "links without external span" do
				expect(helper.link_to_nav(nav_link)).not_to include("glyphicon-new-window")
			end
		end
		context 'external url' do
			let(:external) { true }
			let(:link) { "http://example.org/link?foo=gee" }
			it "links with external span" do
				expect(helper.link_to_nav(nav_link)).to include("glyphicon-new-window")
			end
		end
	end
end
