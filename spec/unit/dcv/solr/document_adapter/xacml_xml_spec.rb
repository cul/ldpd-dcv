require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::XacmlXml, type: :unit do
  let(:xml_src) { fixture(File.join("xacml", "access-open.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { described_class.new(ng_xml) }
  let(:solr_doc) { adapter.to_solr }
  let(:all_text) { solr_doc['all_text_teim'] }
  let(:all_text_joined) { all_text.join(' ') }
  describe ".to_solr" do
    it "should produce a hash" do
      expect(solr_doc).to be_a Hash
    end
    context "initialized with non-Xacml content" do
      let(:xml_src) { fixture(File.join("dc", "dc.xml")) }
      it do
        expect(solr_doc).to be
        expect(solr_doc).to be_empty
      end
    end
  end
end
