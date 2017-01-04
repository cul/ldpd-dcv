require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Dcv::StringHelper. For example:
#
# describe Dcv::StringHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe Dcv::StringHelper, :type => :helper do
  context "#first_sort_letter_for_string" do
    subject { helper.first_sort_letter_for_string(test_string) }

    context "should return downcase first letter of a string that starts with a letter" do
      let(:test_string) { "Yankovic, Weird Al" }
      it { is_expected.to eql('y')}
    end

    context "should return the first number of a string that starts with a number" do
      let(:test_string) { "1 Rockefeller Plaza" }
      it { is_expected.to eql('1')}
    end

    context "should return downcase first letter of string that starts with several non-alphanumeric characters followed by a letter" do
      let(:test_string) { "'''Name" }
      it { is_expected.to eql('n')}
    end

    context "should return the first number of string that starts with several non-alphanumeric characters followed by a number" do
      let(:test_string) { "'''123 Numbers" }
      it { is_expected.to eql('1')}
    end

    context "should skip Unicode 'Letter: Mark' characters and return the first letter or number present in a string" do
      let(:test_string) { "ʹSaraf, Yiḥya ben Avraham, ha-Leṿi" }
      it { is_expected.to eql('s')}
    end

    context "should transliterate characters (like 'À' to 'A') when there are similar English equivalents" do
      let(:test_string) { "Àbcde" }
      it { is_expected.to eql('a')}
    end

    context "should return a non-English unicode first character when no transliterated English equivalent is available (Greek example)" do
      let(:test_string) { "Ψ" }
      it { is_expected.to eql('Ψ')}
    end

    context "should return a non-English unicode first character when no transliterated English equivalent is available (Japanese example)" do
      let(:test_string) { "私はパイナップルです" }
      it { is_expected.to eql('私')}
    end
  end  
end
