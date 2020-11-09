require 'rails_helper'

describe Dcv::Sites::Import::Solr, type: :unit do
  describe ".new" do
    it "should wrap hash arguments in SolrDocument" do
      expect(described_class.new({key: :value}).instance_variable_get(:@document)).to be_a SolrDocument
    end
  end
end
