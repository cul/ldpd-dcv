require 'rails_helper'
describe ArchivalContext do
  subject { ArchivalContext.from_json(json) }
  let(:json) { fixture('json/archival_context.json').read }
  it { is_expected.to have_attributes(id: "http://id.library.columbia.edu/term/72fcfd07-f7db-4a18-bdb2-beb0abce071c") }
  it { is_expected.to have_attributes(title: "Carnegie Corporation of New York Records") }
  it { is_expected.to have_attributes(type: "collection") }
  it { is_expected.to have_attributes(bib_id: "4079753") }
  it { is_expected.to have_attributes(catalog_url: "https://clio.columbia.edu/catalog/4079753") }
  describe "#roman_to_arabic" do
    it "works" do
      expect(ArchivalContext.roman_to_arabic('I')).to be 1
      expect(ArchivalContext.roman_to_arabic('II')).to be 2
      expect(ArchivalContext.roman_to_arabic('IV')).to be 4
      expect(ArchivalContext.roman_to_arabic('V')).to be 5
      expect(ArchivalContext.roman_to_arabic('XIV')).to be 14
      expect(ArchivalContext.roman_to_arabic('XIX')).to be 19
      expect(ArchivalContext.roman_to_arabic('XXVII')).to be 27
      expect(ArchivalContext.roman_to_arabic('LXVI')).to be 66
      expect(ArchivalContext.roman_to_arabic('CLXVI')).to be 166
    end
  end
end