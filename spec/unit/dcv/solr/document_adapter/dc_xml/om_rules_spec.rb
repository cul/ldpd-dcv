require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::DcXml, type: :unit do
  let(:xml_src) { fixture(File.join("dc", "dc.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { described_class.new(ng_xml) }
  let(:solr_doc) { adapter.to_solr }
  let(:all_text) { solr_doc['all_text_teim'] }
  let(:all_text_joined) { all_text.join(' ') }

  describe ".to_solr" do
    it "should create the right map for Solr indexing" do
      expect(solr_doc['dc_identifier_ssim']).to eql ["prd.custord.070103a"]
      expect(solr_doc['dc_title_ssm']).to eql ["With William Burroughs, image"]
      expect(solr_doc['dc_title_teim']).to eql ["With William Burroughs, image"]
      expect(solr_doc['dc_type_ssm']).to eql ["Collection"]
      expect(solr_doc['dc_type_sim']).to eql ["Collection"]
    end
  end
end