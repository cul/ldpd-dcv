require 'rails_helper'
describe Site::ConfigurationValues do
	let(:test_class) { Class.new { include Site::ConfigurationValues } }
	let(:test_obj) { test_class.new }
	describe '#boolean_or_nil' do
		it do
			expect(test_obj.boolean_or_nil(true)).to be true
			expect(test_obj.boolean_or_nil("true")).to be true
			expect(test_obj.boolean_or_nil("TRUE")).to be true
			expect(test_obj.boolean_or_nil(false)).to be false
			expect(test_obj.boolean_or_nil(nil)).to be nil
			expect(test_obj.boolean_or_nil("")).to be nil
		end
	end
	describe '#float_or_nil' do
		it do
			expect(test_obj.float_or_nil(1.0)).to be 1.0
			expect(test_obj.float_or_nil(1)).to be 1.0
			expect(test_obj.float_or_nil("1")).to be 1.0
			expect(test_obj.float_or_nil("1.0")).to be 1.0
			expect(test_obj.float_or_nil(nil)).to be nil
			expect(test_obj.float_or_nil("")).to be nil
		end
	end
	describe '#int_or_nil' do
		it do
			expect(test_obj.int_or_nil(1.0)).to be 1
			expect(test_obj.int_or_nil(1)).to be 1
			expect(test_obj.int_or_nil("1")).to be 1
			expect(test_obj.int_or_nil("1.0")).to be 1
			expect(test_obj.int_or_nil(nil)).to be nil
			expect(test_obj.int_or_nil("")).to be nil
		end
	end
	describe '#clean_and_freeze_validated_array' do
		let(:valid){ ['valid'] }
		let(:invalid) { valid + ['invalid'] }
		it do
			expect(test_obj.clean_and_freeze_validated_array([:valid], valid)).to eql valid
			expect(test_obj.clean_and_freeze_validated_array(['valid'], valid)).to eql valid
			expect(test_obj.clean_and_freeze_validated_array(['valid'], valid)).to be_frozen
			expect(test_obj.clean_and_freeze_validated_array(invalid, valid)).to eql valid
			expect(test_obj.clean_and_freeze_validated_array(invalid, valid)).to be_frozen
		end
	end
end