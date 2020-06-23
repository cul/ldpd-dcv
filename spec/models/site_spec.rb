require 'rails_helper'
describe Site do
	let(:site) { FactoryBot.create(:site, slug: site_slug) }
	describe '#initialize' do
		let(:site_slug) { 'initialize' }
		it 'defaults search type to catalog' do
			expect(Site.new.search_type).to eql('catalog')
		end
	end
	describe '#grouped_links' do
		let(:site_slug) { 'grouped_links' }
		let(:site) { FactoryBot.create(:site_with_links, slug: site_slug) }
		let(:unlabeled_menu) { site.grouped_links.detect { |nm| nm.sort_label.nil? } }
		let(:labeled_menu) { site.grouped_links.detect { |nm| !nm.sort_label.nil? } }
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
		end
		context 'on project' do
			before do
				site.project_constraints = values
			end
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('project' => values)
			end
		end
		context 'on publisher' do
			before do
				site.publisher_constraints = values
			end
			it 'adds a collection clause to the constraints hash' do
				expect(site.constraints).to include('publisher' => values)
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