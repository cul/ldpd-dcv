require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')

describe Dcv::Sites::LookupController, type: :unit do
	
	before do
		class TestRig
			attr_reader :params

			def self.rescue_from(*args)
			end
			
			include Dcv::Sites::LookupController

			def initialize(id, params={})
				@document = {id: id}
				@params = params
			end

			def get_solr_response_for_app_id
				# this is a no-op stub
			end
		end

	end

	after do
		Object.send :remove_const, :TestRig
	end

	subject(:controller) { TestRig.new('lol:wut') }
	let(:site) { FactoryBot.create(:site) }
	let(:known_id) { '10.1234/567-abcd' }
	let(:legacy_id) { 'donotuse:1234' }
	let(:solr_doc) { SolrDocument.new(site.default_filters.merge(id: legacy_id, ezid_doi_ssim: ["doi:#{known_id}"])) }

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
		let(:less_site) { FactoryBot.create(:site, scope_filters: [project_scope], slug: 'less', restricted: true) }
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
