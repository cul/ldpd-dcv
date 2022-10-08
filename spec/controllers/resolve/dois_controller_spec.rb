require 'rails_helper'

describe Resolve::DoisController, type: :controller do
	before do
		expect(controller).not_to be_nil
		expect(controller.controller_name).not_to be_nil
	end

	let(:site) { FactoryBot.create(:site) }
	let(:known_id) { '10.1234/567-abcd' }
	let(:legacy_id) { 'donotuse:1234' }
	let(:solr_doc) { SolrDocument.new(site.default_filters.merge(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"])) }

	describe '#doc_url_in_site_context' do
		context 'nil site' do
			let(:solr_doc) { SolrDocument.new(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"]) }
			let(:expected_url) { "http://test.host/catalog/#{known_id}" }
			it 'resolves to catalog url' do
				expect(controller.doc_url_in_site_context(nil, solr_doc)).to eql(expected_url)
			end
		end
		context 'site with catalog search' do
			let(:expected_url) { "http://test.host/catalog/#{known_id}" }
			it 'resolves to catalog url' do
				expect(controller.doc_url_in_site_context(site, solr_doc)).to eql(expected_url)
			end
		end
		context 'site with local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			let(:expected_url) { "http://test.host/dlc_site/#{known_id}" }
			it 'resolves to site url' do
				expect(controller.doc_url_in_site_context(site, solr_doc)).to eql(expected_url)
			end
		end
		context 'site with custom search' do
			let(:template_defined_slug) { 'lcaaj' }
			let(:site) { FactoryBot.create(:site, search_type: 'custom', slug: template_defined_slug) }
			let(:expected_url) { "http://test.host/#{template_defined_slug}/#{legacy_id}" }
			it 'resolves to custom url' do
				expect(controller.doc_url_in_site_context(site, solr_doc)).to eql(expected_url)
			end
		end
	end
	describe '#resolve' do
		let(:template_defined_slug) { 'lcaaj' }
		let(:expected_url) { "http://test.host/#{template_defined_slug}/#{legacy_id}" }
		before do
			allow(controller).to receive(:fetch).and_return([nil, solr_doc])
			allow(controller).to receive(:params).and_return({registrant: known_id.split('/')[0], doi: known_id.split('/')[1]})
			allow(controller).to receive(:scope_candidates_for).and_return([])
			allow(controller).to receive(:site_candidates_for).and_return([])
			allow(controller).to receive(:site_matches_for).and_return([])
			allow(controller).to receive(:best_site_for).and_return(site)
			allow(controller).to receive(:doc_url_in_site_context).and_return(expected_url)
		end
		it 'redirects to resolved url' do
			expect(controller).to receive(:redirect_to).with(expected_url)
			controller.resolve
		end
		context 'for a site record' do
			let(:solr_doc) { Dcv::Sites::Export::Solr.new(site).run }
			let(:expected_url) { "http://test.host/#{site.slug}" }
			it 'redirects to resolved url' do
				expect(controller).to receive(:redirect_to).with(expected_url)
				controller.resolve
			end
		end
	end
	describe '#match_score_for' do
		context 'site is the main catalog' do
			let(:site) { FactoryBot.create(:site, slug: 'catalog') }
			it "returns 1" do
				expect(controller.match_score_for(site, solr_doc)).to be 1
			end
		end
		context 'site criteria match fields' do
			it "returns a positive score" do
				expect(controller.match_score_for(site, solr_doc)).to be > 0
			end
		end
		context 'site criteria do not match fields' do
			let(:solr_doc) { SolrDocument.new(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"]) }
			it "returns 0" do
				expect(controller.match_score_for(site, solr_doc)).to be 0
			end
		end
		context 'site is nil' do
			it "returns -1" do
				expect(controller.match_score_for(nil, solr_doc)).to be -1
			end
		end
		context 'solr doc is nil' do
			it "returns -1" do
				expect(controller.match_score_for(nil, solr_doc)).to be -1
			end
		end
	end
	describe '#best_site_for' do
		let(:project_value) { 'ProjectValue' }
		let(:solr_doc) { SolrDocument.new(site.default_filters.merge(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"], lib_project_short_ssim: [project_value])) }
		let(:project_scope) { FactoryBot.build(:scope_filter, filter_type: 'project', value: project_value) }
		let(:best_site) { FactoryBot.create(:site, scope_filters: [project_scope], slug: 'best') }
		it "returns the highest scoring site" do
			expect(controller.best_site_for(solr_doc, [site, best_site])).to eql(best_site)
		end
	end
	describe '#scope_candidates_for' do
		it "maps solr values to scope types" do
			expect(controller.scope_candidates_for(solr_doc)).to eql(site.constraints)
		end
	end
	describe '#site_matches_for' do
		let(:project_value) { 'ProjectValue' }
		let(:project_scope) { FactoryBot.build(:scope_filter, filter_type: 'project', value: project_value) }
		let(:collection_scope) { FactoryBot.build(:scope_filter, filter_type: 'collection', value: 'DLC Site Collection') }
		let(:partial_site) { FactoryBot.create(:site, scope_filters: [project_scope, collection_scope], slug: 'partial') }
		let(:site_candidates) { [site, partial_site] }
		it "filters partially matched sites" do
			expect(controller.site_matches_for(solr_doc, site_candidates)).to eql([site])
		end
		context "all sites match all criteria" do
			let(:solr_doc) { SolrDocument.new(site.default_filters.merge(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"], lib_project_short_ssim: [project_value])) }
			it "filters no sites" do
			end
		end
	end
	describe '#site_candidates_for'
end
