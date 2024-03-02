require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ModsXml, type: :unit do
  let(:adapter) { described_class.new(nil) }

  describe ".key_date_year_bounds" do
    it "assigns normal CE dates correctly" do
      expect(adapter.key_date_year_bounds('1901-01-02', '1902-02-03')).to eql(['1901', '1902'])
    end
    it "assigns reversed CE dates correctly" do
      expect(adapter.key_date_year_bounds('1902-01-02', '1901-02-03')).to eql([nil, nil])
    end
    it "expands u-encoded uncertain CE dates correctly" do
      expect(adapter.key_date_year_bounds('19uu', nil)).to eql(['1900', '1999'])
    end
    it "expands u-encoded uncertain BCE dates correctly" do
      expect(adapter.key_date_year_bounds('-19uu', nil)).to eql(['-1999', '-1900'])
    end
  end

  describe ".date_range_to_textual_date" do
    it "assigns normal CE dates correctly" do
      expect(adapter.date_range_to_textual_date('1901', '1902')).to eql(['Between 1901 and 1902'])
    end
    it "assigns normal BCE dates correctly" do
      expect(adapter.date_range_to_textual_date('-1901', '-1802')).to eql(['Between 1901 and 1802 BCE'])
    end
    it "assigns mixed-era dates correctly" do
      expect(adapter.date_range_to_textual_date('-1901', '1802')).to eql(['Between 1901 BCE and 1802 CE'])
    end
    it "assigns start-only dates correctly" do
      expect(adapter.date_range_to_textual_date('-1900', nil)).to eql(['After 1900 BCE'])
    end
    it "assigns end-only dates correctly" do
      expect(adapter.date_range_to_textual_date(nil, '-1900')).to eql(['Before 1900 BCE'])
    end
    it "assigns nothing when nil args" do
      expect(adapter.date_range_to_textual_date(nil, nil)).to be_nil
    end
  end
end
