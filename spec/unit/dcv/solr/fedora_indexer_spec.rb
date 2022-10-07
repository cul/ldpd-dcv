require 'rails_helper'

describe Dcv::Solr::FedoraIndexer, type: :unit do
	describe '#extract_index_opts' do
		context 'with empty arguments' do
			let(:args) { [] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'returns defaults' do
				expect(extracted_opts).to eq(described_class::DEFAULT_INDEX_OPTS)
			end
		end
		context 'with legacy positional arguments' do
			let(:args) { [:skip_generic_resources, :verbose_output, :softcommit] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'retains legacy positional arguments' do
				expected_opts = args.map {|arg| [arg, arg] }.to_h.merge(reraise: false)
				expect(extracted_opts).to  eq(expected_opts)
			end
		end
		context 'with an opts hash' do
			let(:args) { [{ reraise: true }] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'extracts merges into defaults' do
				expect(extracted_opts).to eq(described_class::DEFAULT_INDEX_OPTS.merge(args.first))
			end
		end
	end
	describe '#index_pid' do
		let(:index_opts) { { skip_generic_resources: false, softcommit: true, reraise: true } }
		let(:mock_object) { ActiveFedora::Base.new }
		let(:pid) { 'abc:123' }
		before do
			mock_object.add_relationship(:has_model, 'info:fedora/ldpd:GenericResource')
			expect(ActiveFedora::Base).to receive(:find).with(pid, any_args).and_return(mock_object)
		end
		it "looks up an object and calls update_index" do
			expect(ActiveFedora::SolrService).to receive(:add)
			described_class.index_pid(pid, index_opts)
		end
		context 'skipping generic resources' do
			let(:index_opts) { { skip_generic_resources: true, softcommit: true, reraise: true } }
			it "does not index a generic resource" do
				expect(ActiveFedora::SolrService).not_to receive(:add)
				described_class.index_pid(pid, index_opts)
			end
		end
	end
end