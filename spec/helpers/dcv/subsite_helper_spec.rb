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
	let(:site_slug) { 'siteSlug' }
	let(:nav_link) { NavLink.new(link: link, external: external, sort_label: sort_label) }
	let(:sort_label) { '00:Link Label' }
	let(:subsite) { Site.new(slug: site_slug) }
	before do
		allow(controller).to receive(:subsite_config).and_return(slug: site_slug)
		allow(controller).to receive(:load_subsite).and_return(subsite)
		helper.instance_variable_set(:@subsite, subsite)
	end
	describe "#link_to_site_browse" do
		let(:external_label) { "Go To Site" }
		let(:internal_label) { "Browse Site Content" }
		let(:persistent_url) { "http://example.org" }
		before do
			subsite.persistent_url = persistent_url
		end
		context 'has no constraints' do
			it "links to persistent_url link with external label" do
				expect(helper.link_to_site_browse(internal_label, external_label)).to include(external_label)
				expect(helper.link_to_site_browse(internal_label, external_label)).to include(persistent_url)
			end
		end
		context 'has constraints' do
			let(:search_action_url) { "/catalog?search_field=all_text_teim&q=" }
			before do
				subsite.scope_filters << ScopeFilter.new(filter_type: 'project', value: 'a value')
				allow(controller).to receive(:blacklight_config).and_return(subsite.blacklight_config)
			end
			it "links to search link with internal label" do
				expect(helper).to receive(:search_action_url).and_return(search_action_url)
				expect(helper.link_to_site_browse(internal_label, external_label)).to include(internal_label)
			end
		end
	end
	describe "#link_to_nav" do
		context 'site page by slug' do
			let(:external) { false }
			let(:link) { 'slug' }
			let(:expected_path) { '/siteSlug/slug' }
			it "links to site_page" do
				expect(helper).to receive(:site_page_path).with({ site_slug: site_slug, slug: link }).and_return(expected_path)
				helper.link_to_nav(nav_link)
			end
			context 'with an anchor' do
				let(:link) { 'slug#anchor' }
				it "links to site_page with anchor" do
					expect(helper).to receive(:site_page_path).with({ site_slug: site_slug, slug: 'slug', anchor: 'anchor' }).and_return(expected_path)
					helper.link_to_nav(nav_link)
				end
			end
		end
		context 'relative url' do
			let(:external) { true }
			let(:link) { "/link?foo=gee" }
			it "links without external span" do
				expect(helper.link_to_nav(nav_link)).not_to include("fa-external-link")
			end
		end
		context 'external url' do
			let(:external) { true }
			let(:link) { "http://example.org/link?foo=gee" }
			it "links with external span" do
				expect(helper.link_to_nav(nav_link)).to include("fa-external-link")
			end
		end
	end
end
