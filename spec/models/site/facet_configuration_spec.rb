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
	describe '#facet_fields_form_value=' do
		context 'single value' do
			let(:atts) { {'facet_fields_form_value' => 'root'} }
			it "sets field_name but not pivot" do
				expect(config.field_name).to eql('root')
				expect(config.pivot).to be_nil
			end
		end
		context 'multiple values' do
			let(:atts) { {'facet_fields_form_value' => 'root,branch,leaf'} }
			it "sets both field_name and pivot" do
				expect(config.field_name).to eql('root')
				expect(config.pivot).to eql(['branch', 'leaf'])
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
	describe '#configure' do
		let(:blacklight_config) { instance_double(Blacklight::Configuration) }
		it 'returns false without configuring when field_name is blank' do
			expect(blacklight_config).not_to receive(:add_facet_field)
			expect(config.configure(blacklight_config)).to be false
		end
	end
end