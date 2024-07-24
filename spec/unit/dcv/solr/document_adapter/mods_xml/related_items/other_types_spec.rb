require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ModsXml, type: :unit do
  let(:xml_src) { fixture(File.join("mods", "mods-all.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { described_class.new(ng_xml) }
  let(:solr_doc) { adapter.to_solr }
  let(:all_text) { solr_doc['all_text_teim'] }
  let(:all_text_joined) { all_text.join(' ') }

  describe ".to_solr" do
    subject {
      solr_doc
    }
    context "has otherType project cataloged" do
      let(:xml_src) { fixture( File.join("mods", "mods-relateditem-project.xml") ) }
      let(:project_label) { 'Project 2508: Edna Gladney house (Fort Worth, Texas). Scheme 2, Unbuilt Project' }
      it "should extract project labels" do
        expect(subject["rel_other_project_ssim"]).to eq([project_label])
      end
    end    
  end
end