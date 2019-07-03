require 'rails_helper'
describe SubsiteConfig do
	let(:sites) {
		{
			'top' => {
				'uri' => 'top-uri',
				'property' => 'top-property',
				'nested' => {
					'nest' => {
						'uri' => 'nest-uri',
						'property' => 'nest-property' 
					}
				}
			}
		}
	}
	describe '.dig_sites' do
		context "top level site" do
			let(:uri) { 'top-uri' }
			let(:expected) { 'top-property' }
			let(:actual) { described_class.dig_sites(sites, uri)['property'] }
			it { expect(actual).to eql(expected) }
		end
		context "nested site" do
			let(:uri) { 'nest-uri' }
			let(:expected) { 'nest-property' }
			let(:actual) { described_class.dig_sites(sites, uri)['property'] }
			it { expect(actual).to eql(expected) }
		end
	end
end