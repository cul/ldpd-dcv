require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')

describe Dcv::Catalog::DateRangeSelectorBehavior, type: :unit do
  
  before do
    class TestRig
      attr_reader :params

      def self.rescue_from(*args)
      end
      
      include Dcv::Catalog::DateRangeSelectorBehavior
    end

  end
  after do
    Object.send :remove_const, :TestRig
  end
  subject(:controller) { TestRig.new }
  describe '#counts_by_year_ranges_from_facet_data' do
    let(:facet_data) do
      ['1492-1619', 3, '1215-1776', 5, '1865-1865', 4]
    end
    let(:earliest_start_year) { controller.counts_by_year_ranges_from_facet_data(facet_data)[1] }
    let(:latest_end_year) { controller.counts_by_year_ranges_from_facet_data(facet_data)[2] }
    it "returns expected values" do
      expect(earliest_start_year).to be 1215
      expect(latest_end_year).to be 1865
    end
    context "malformed data" do
      let(:facet_data) do
        ['1984-1982', 5]
      end
      it "returns nils" do
        expect(earliest_start_year).to be_nil
        expect(latest_end_year).to be_nil
      end
    end
    context "invalid data" do
      let(:facet_data) do
        ['-@8a1982', 5]
      end
      it "returns nils" do
        expect(earliest_start_year).to be_nil
        expect(latest_end_year).to be_nil
      end
    end
    context "negative years" do
      let(:facet_data) do
        ['-1984--1982', 5]
      end
      it "returns nils" do
        expect(earliest_start_year).to be -1984
        expect(latest_end_year).to be -1982
      end
    end
    context "mixed years" do
      let(:facet_data) do
        ['-1984-1982', 5]
      end
      it "returns nils" do
        expect(earliest_start_year).to be -1984
        expect(latest_end_year).to be 1982
      end
      context "in wrong order" do
        let(:facet_data) do
          ['1984--1982', 5]
        end
        it "returns nils" do
          expect(earliest_start_year).to be_nil
          expect(latest_end_year).to be_nil
        end
      end
    end
  end
end
