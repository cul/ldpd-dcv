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
			context 'and nested access' do
				let(:template_defined_slug) { 'carnegie/centennial' }
				let(:site) { FactoryBot.create(:site, search_type: 'custom', slug: template_defined_slug) }
				let(:expected_url) { "http://test.host/#{template_defined_slug}/#{legacy_id}" }
				it 'resolves to custom url' do
					expect(controller.doc_url_in_site_context(site, solr_doc)).to eql(expected_url)
				end
			end
			context 'and restricted access' do
				let(:template_defined_slug) { 'restricted/ifp' }
				let(:site) { FactoryBot.create(:site, search_type: 'custom', slug: template_defined_slug, restricted: true) }
				let(:expected_url) { "http://test.host/#{template_defined_slug}/#{legacy_id}" }
				it 'resolves to custom url' do
					expect(controller.doc_url_in_site_context(site, solr_doc)).to eql(expected_url)
				end				
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
		context 'for a non-existent document' do
			let(:solr_doc) { nil }
			let(:expected_url) { "http://test.host/tombstone/#{known_id}" }
			it 'redirects to resolved url' do
				expect(controller).to receive(:redirect_to).with(expected_url)
				controller.resolve
			end
		end
	end
end
