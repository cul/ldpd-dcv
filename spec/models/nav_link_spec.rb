require 'rails_helper'
describe NavLink do
	let(:about_label) { 'Surprising But Effective Label' }
	let(:about_link) { FactoryBot.build(:nav_link, external: false, sort_label: "00:#{about_label}", link: 'about') }
	describe '#label' do
		it 'removes sort prefix' do
			expect(about_link.label).to eql(about_label)
		end
	end
	describe '#about_link?' do
		subject { about_link }
		it { is_expected.to be_about_link }
		context "external links are not about link" do
			subject { FactoryBot.build(:nav_link, external: true, sort_label: "00:#{about_label}", link: 'https://about.org') }
			it { is_expected.not_to be_about_link }
		end
		context "internal links to other pages are not about link" do
			subject { FactoryBot.build(:nav_link, external: false, sort_label: "00:#{about_label}", link: 'not_about') }
			it { is_expected.not_to be_about_link }
		end
	end
end