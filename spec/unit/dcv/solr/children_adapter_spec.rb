require 'rails_helper'

describe Dcv::Solr::ChildrenAdapter, type: :unit do
	let(:authorizer) { nil }
	let(:searcher) { instance_double(Dcv::Sites::SearchableController) }
	let(:title_field) { nil }

	subject(:adapter) { described_class.new(searcher, authorizer) }

	describe '#initialize' do
		context 'passed search and adapter args' do
			it 'creates an adapter' do
				expect(adapter).to be_present
			end
		end
	end

	describe '#from_aspace_parent' do
		let(:aspace_parent_id) { 'abcdef1234567890abcdef1234567890' }
		let(:page_size) { described_class::ASPACE_PAGE_SIZE }
		# let(:repository) { instance_double(Blacklight::Solr::Repository) }
		let(:search_builder) { instance_double(SearchBuilder) }
		let(:search_service) { instance_double(Dcv::SearchService) }
		let(:searcher) { instance_double(Dcv::Sites::SearchableController, search_service: search_service) }
		let(:solr_response) {
			instance_double(Blacklight::Solr::Response, documents: document_list, aggregations: {}, **pagination_stubs)
		}

		context 'one or fewer pages of results from solr' do
			let(:pagination_stubs) {
			  {
				prev_page: nil, next_page: nil, total_pages: 1, current_page: 1, limit_value: page_size, total_count: document_list.length,
				offset_value: 0, :first_page? => true, :last_page? => true
			  }
			}
			let(:expected_filter_query) { "#{Iiif::Collection::ArchivesSpaceCollection::SOLR_PARENT_FIELD}:\"#{aspace_parent_id}\"" }
			before do
				# allow(repository).to receive(:search).with(search_builder).once.and_return(solr_response)
				allow(search_builder).to receive(:merge).with hash_including(fq: [expected_filter_query])
				allow(search_builder).to receive(:start=).once.with(0)
				allow(search_builder).to receive(:rows=).once.with(page_size)
				allow(search_service).to receive(:search_results).and_yield(search_builder).and_return([solr_response, document_list])
			end

			context 'and zero actual results' do
				let(:document_list) { [] }
				it 'returns an empty array' do
					expect(adapter.from_aspace_parent(aspace_parent_id)).to be_empty
				end
			end
		end
	end
end