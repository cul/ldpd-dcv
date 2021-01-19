require 'rails_helper'
describe Site::FacetConfiguration do
	let(:atts) { {} }
	let(:config) { Site::FacetConfiguration.new(atts) }
	describe '#value_transforms=' do
		let(:atts) { { value_transforms: Site::FacetConfiguration::VALID_VALUE_TRANSFORMS } }
		context 'with bad value included' do
			before { config.value_transforms = config.value_transforms + ['bad_value'] }
			it 'ignores the bad_value' do
				expect(config.value_transforms).to eql(Site::FacetConfiguration::VALID_VALUE_TRANSFORMS)
				expect(config.changed?).to be false
			end
		end
		context 'with order changed' do
			before { config.value_transforms = config.value_transforms.reverse }
			it 'updates the values' do
				expect(config.value_transforms).to eql(Site::FacetConfiguration::VALID_VALUE_TRANSFORMS.reverse)
				expect(config.changed?).to be true
			end
		end
	end
	describe '#eql?' do
		it 'returns true when attributes are equal' do
			expect(config.eql?(described_class.new(atts))).to be true
		end
		it 'returns false when attributes are unequal' do
			expect(config.eql?(described_class.new(atts.merge(limit: config.limit - 1)))).to be false
		end
	end
end