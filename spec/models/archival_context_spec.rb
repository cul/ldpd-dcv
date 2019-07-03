require 'rails_helper'
describe ArchivalContext do
  subject { described_class.from_json(json) }
  let(:json) { fixture('json/archival_context.json').read }
  it { is_expected.to have_attributes(id: "http://id.library.columbia.edu/term/72fcfd07-f7db-4a18-bdb2-beb0abce071c") }
  it { is_expected.to have_attributes(title: "Carnegie Corporation of New York Records") }
  it { is_expected.to have_attributes(type: "collection") }
  it { is_expected.to have_attributes(bib_id: "4079753") }
  it { is_expected.to have_attributes(catalog_url: "https://clio.columbia.edu/catalog/4079753") }
  it { expect(described_class::ROMAN_SERIES).to match("Series XI. Audio Visual Materials. XI.A. Corporation") }
  describe "#roman_to_arabic" do
    it "works" do
      expect(described_class.roman_to_arabic('I')).to be 1
      expect(described_class.roman_to_arabic('II')).to be 2
      expect(described_class.roman_to_arabic('IV')).to be 4
      expect(described_class.roman_to_arabic('V')).to be 5
      expect(described_class.roman_to_arabic('XIV')).to be 14
      expect(described_class.roman_to_arabic('XIX')).to be 19
      expect(described_class.roman_to_arabic('XXVII')).to be 27
      expect(described_class.roman_to_arabic('LXVI')).to be 66
      expect(described_class.roman_to_arabic('CLXVI')).to be 166
    end
  end
  describe "#title_for" do
    subject { described_class.from_json(json) }
    let(:json) { fixture('json/archival_context_caps.json').read }
    let(:subseries) { JSON.parse(json)['dc:coverage'][0]['dc:hasPart'] }
    let(:title_for) { subject.title_for(subseries, link: true) }
    before { subject.repo_code = 'NyNyTest' }
    it { expect(title_for).to include('nynytest/ldpd_4079753/dsc/11#subseries_1') }
  end
end