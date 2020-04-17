require 'rails_helper'
describe IndexFedoraObjectJob do
	describe '#perform' do
		let(:pid) { 'abc:123' }
		let(:condition_key) { 'test_condition' }
		let(:condition_value) { 'Example Condition Value' }
		let(:conditions) { { condition_key => condition_value, 'pid' => pid } }
		let(:expected_args) { described_class::DEFAULT_OPTS.merge(condition_key.to_sym => condition_value) }
		it 'correctly constructs indexer arguments from conditions' do
			indexer_class = class_double("Cul::Hydra::Indexer").as_stubbed_const(:transfer_nested_constants => true)
			expect(indexer_class).to receive(:index_pid).with(pid, expected_args)
			described_class.perform(conditions)
		end
	end
end