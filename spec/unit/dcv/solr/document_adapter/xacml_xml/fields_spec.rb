require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::XacmlXml, type: :unit do
  let(:xml_src) { fixture(File.join("xacml", "access-open.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { described_class.new(ng_xml) }
  let(:solr_doc) { adapter.to_solr }
  let(:all_text) { solr_doc['all_text_teim'] }
  let(:all_text_joined) { all_text.join(' ') }

  describe '#to_solr' do
    context "has permissions" do
      let(:xml_src) { fixture(File.join("xacml", "access-conditions.xml")) }
      it "has permitted affils" do
        expect(solr_doc['access_control_affiliations_ssim']).to eql(['LIB_role-ext-UnivSemArchives'])
      end
      it "has permitted locations" do
        expect(solr_doc['access_control_locations_ssim']).to eql(['http://id.library.columbia.edu/term/45487bbd-97ef-44b4-9468-dda47594bc60'])
      end
      it "has permitted date" do
        expect(solr_doc['access_control_embargo_dtsi']).to eql('2099-01-01T00:00:00Z')
      end
      it "has permissions flag" do
        expect(solr_doc['access_control_permissions_bsi']).to be true
      end
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Embargoed','On-site Access','Specified Group/UNI Access'])
      end
      it "has no suppress random flag" do
        expect(solr_doc['suppress_in_random_bsi']).to be false
      end
    end
    context "is closed" do
      let(:xml_src) { fixture(File.join("xacml", "access-closed.xml")) }
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Closed'])
      end
    end
    context "is open" do
      let(:xml_src) { fixture(File.join("xacml", "access-open.xml")) }
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Public Access'])
      end
    end
    context "is flagged no-random" do
      let(:xml_src) { fixture(File.join("xacml", "no-random.xml")) }
      it "has suppress random flag" do
        expect(solr_doc['suppress_in_random_bsi']).to be true
      end
    end
    context "has blank embargo date" do
      let(:xml_src) { fixture(File.join("xacml", "embargo", "blank-date.xml")) }      
      it "has permitted date" do
        expect(DateTime.iso8601(solr_doc['access_control_embargo_dtsi'])).to be > (DateTime.now + 39.years)
      end
    end
    context "has invalid embargo date" do
      let(:xml_src) { fixture(File.join("xacml", "embargo", "bad-date.xml")) }      
      it "has permitted date" do
        expect(DateTime.iso8601(solr_doc['access_control_embargo_dtsi'])).to  be > (DateTime.now + 39.years)
      end
    end
  end
end