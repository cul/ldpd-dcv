require 'rails_helper'
describe SiteTextBlock do
	let(:export_filename) { '03_Block%27s_Title_of_Text%2C_Other_Things%2C_and_%22quotes%22.md' }
	let(:sort_label) { '03:Block\'s Title of Text, Other Things, and "quotes"' }
	let(:label) { 'Block\'s Title of Text, Other Things, and "quotes"' }

	describe '.export_filename_for_sort_label' do
		subject { described_class.export_filename_for_sort_label(sort_label) }
		it { is_expected.to eql(export_filename) }
	end
	describe '.sort_label_from_filename' do
		subject { described_class.sort_label_from_filename(export_filename) }
		it { is_expected.to eql(sort_label) }
	end
	describe '#label' do
		subject { described_class.new(sort_label: sort_label).label }
		it { is_expected.to eql(label) }
	end
end