require 'rails_helper'
describe Site do
	let(:site) { FactoryBot.create(:site, slug: site_slug) }
	describe '#initialize' do
		let(:site_slug) { 'initialize' }
		it 'defaults search type to catalog' do
			expect(Site.new.search_type).to eql('catalog')
		end
	end
	describe '#nav_menus' do
		let(:site_slug) { 'grouped_links' }
		let(:site) { FactoryBot.create(:site_with_links, slug: site_slug) }
		let(:unlabeled_menu) { site.nav_menus.detect { |nm| nm.sort_label.nil? } }
		let(:labeled_menu) { site.nav_menus.detect { |nm| !nm.sort_label.nil? } }
		it 'groups links according to sort group' do
			expect(labeled_menu.label).to eql('Project History')
			expect(labeled_menu.length).to eql(2)
			expect(unlabeled_menu.label).to be_blank
			expect(unlabeled_menu.length).to eql(1)
		end
	end
	describe 'constraints' do
		let(:site_slug) { 'constraints' }
		let(:values) { [ 'constraints_value_1' ] }
		context 'on collection' do
			before do
				site.collection_constraints = values
			end
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('collection' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('lib_collection_sim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("lib_collection_sim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("lib_collection_sim:(\"#{values.first}\")")
			end
		end
		context 'on project' do
			before do
				site.project_constraints = values
			end
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('project' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('lib_project_short_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("lib_project_short_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("lib_project_short_ssim:(\"#{values.first}\")")
			end
		end
		context 'on publisher' do
			before do
				site.publisher_constraints = values
			end
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('publisher' => values)
			end
			it 'represents the clause in the default filters' do
				expect(site.default_filters).to include('publisher_ssim' => values)
			end
			it 'represents the clause in the default fq' do
				expect(site.default_fq).to include("publisher_ssim:(\"#{values.first}\")")
			end
			it 'adds the clause to the local blacklight config' do
				site.configure_blacklight!
				expect(site.blacklight_config.default_solr_params[:fq]).to include("publisher_ssim:(\"#{values.first}\")")
			end
		end
	end
	describe 'image uri methods' do
		let(:site_slug) { 'image_uris' }
		describe '#image_uris' do
			it 'returns an array' do
				expect(site.image_uris).to be_a Array
			end
		end
		describe '#image_uris=' do
			let(:additional_value) { "info:fedora/fake:1" }
			it 'accepts an array' do
				site.image_uris << additional_value
				site.save
				expect(site.image_uris.length).to be 2
				site.image_uris = [additional_value]
				site.save
				expect(site.image_uris.length).to be 1
				expect(site.image_uri).to eql additional_value
			end
			it 'rejects a string' do
				expect { site.image_uris = additional_value }.to raise_error
			end
		end
		describe '#image_uri' do
			it 'returns a single uri selected from an array' do
				expect(site.image_uri).to be_a String
			end
		end
	end
	describe '#to_subsite_config' do
		let(:site_slug) { 'to_subsite_config' }
		let(:subject) { site.to_subsite_config }
		it "converts to a hash" do
			is_expected.to be_a Hash
			expect(subject[:slug]).to eql site_slug
			expect(subject[:restricted]).not_to be
			expect(subject[:palette]).to eql 'monochromeDark'
		end
	end
end