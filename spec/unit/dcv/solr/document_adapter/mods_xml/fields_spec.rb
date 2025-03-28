require 'rails_helper'

describe Dcv::Solr::DocumentAdapter::ModsXml, type: :unit do
  let(:xml_src) { fixture(File.join("mods", "mods-all.xml")) }
  let(:ng_xml) { Nokogiri::XML(xml_src.read) }
  let(:adapter) { described_class.new(ng_xml) }
  let(:solr_doc) { adapter.to_solr }
  let(:all_text) { solr_doc['all_text_teim'] }
  let(:all_text_joined) { all_text.join(' ') }

  describe ".to_solr" do
    it "should have a single sortable title" do
      expect(solr_doc).to include("title_si" => 'MANUSCRIPT UNIDENTIFIED')
      # title_display_ssm is assigned in the ModsDocument OM selector
      expect(solr_doc).to include("title_ssm" => ['The Manuscript, unidentified'])
    end

    it "should have normalized facet values" do
      expect(solr_doc["lib_collection_sim"]).to eql ['Collection Facet Normalization Test']
    end

    it "should facet on corporate and personal names, ignoring roleTerms" do
      expect(solr_doc["lib_name_sim"]).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
      expect(solr_doc["lib_name_teim"]).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
    end

    it "should include /mods/subject/name/namePart elements in the list of subject elements" do
      expect(solr_doc["lib_all_subjects_ssm"]).to include('Jay, John, 1745-1829')
      expect(solr_doc["lib_all_subjects_teim"]).to include('Jay, John, 1745-1829')
    end

    it "should not include /mods/subject/name/nameIdentifier elements in the list of subject elements" do
      expect(solr_doc["lib_all_subjects_ssm"]).not_to include('http://id.loc.gov/authorities/names/n79088877')
    end
    it "should include /mods/subject/name valueURI attributes in the list of value URIs" do
      expect(solr_doc["value_uri_ssim"]).to include('http://id.loc.gov/authorities/names/n79088877')
      expect(solr_doc["all_text_teim"]).to include('http://id.loc.gov/authorities/names/n79088877')
    end

    it "should not include /mods/subject/name/namePart elements in the list of /mods/name elements" do
      expect(solr_doc["lib_name_sim"]).not_to include('Jay, John, 1745-1829')
      expect(solr_doc["lib_name_teim"]).not_to include('Jay, John, 1745-1829')
    end

    it "should not include /mods/relatedItem/identifier[type='CLIO'] elements in the list of clio_identifier elements" do
      expect(solr_doc["clio_ssim"]).to include('12381225')
      expect(solr_doc["clio_ssim"]).not_to include('4080189')
    end

    it "should facet on the special library format values" do
      expect(solr_doc["lib_format_sim"]).to eql ['books']
    end
  end

  describe ".normalize" do
    it "should strip trailing and leading whitespace and normalize remaining space" do
      d = "   Foo \n Bar "
      e = "Foo Bar"
      a = described_class.normalize(d)
      expect(a).to eql e
    end

    it "should only strip punctuation when asked to" do
      d = "   'Foo \n Bar\" "
      e = "'Foo Bar\""
      a = described_class.normalize(d)
      expect(a).to eql e
      e = "Foo Bar\""
      a = described_class.normalize(d, true)
      expect(a).to eql e
      d = "<Jay, John (Pres. of Cong.)>"
      e = "Jay, John (Pres. of Cong.)"
      a = described_class.normalize(d, true)
      expect(a).to eql e
    end
  end

  describe '.role_text_to_solr_field_name' do
    let(:expected_values) do
      {
        'Author' => 'role_author_ssim',
        'Owner/Agent' => 'role_owner_agent_ssim',
        'Mixed case Role with Spaces' => 'role_mixed_case_role_with_spaces_ssim',
        'WAYYY      too much       space' => 'role_wayyy_too_much_space_ssim',
        '!! Adjacent Replaced Characters !!! collapsed into one' => 'role_adjacent_replaced_characters_collapsed_into_one_ssim'
      }
    end
    it "converts as expected" do
      expected_values.each do |role, expected_value|
        expect(described_class.role_text_to_solr_field_name(role)).to eq(expected_value)
      end
    end
  end

  describe ".main_title" do
    let(:xml_src) { fixture( File.join("mods", "mods-titles.xml")) }
    it "should find the top-level titles" do
      expect(adapter.main_title).to eql 'The Photographs'
    end
  end

  describe ".project_titles" do
    let(:xml_src) { fixture( File.join("mods", "mods-titles.xml")) }
    it "should find the project titles for faceting" do
      expect(adapter.project_titles).to eql ['Customer Order Project']
    end
    context "a project title has periods in it" do
      let(:xml_src) { fixture( File.join("mods", "mods-relateditem-project.xml")) }
      it "should be able to translate the title value" do
        expect(solr_doc["lib_project_short_ssim"]).to include "Lindquist Photographs"
        expect(solr_doc["lib_project_full_ssim"]).to include "G.E.E. Lindquist Native American Photographs"
      end
    end
  end

  describe ".project_keys" do
    context "the description has a single project" do
      let(:xml_src) { fixture( File.join("mods", "mods-titles.xml")) }
      it "should find the project titles for faceting" do
        expect(adapter.project_keys).to eql ['customer_orders']
      end
    end
    context "the description has a primary and auxiliary project" do
      let(:xml_src) { fixture( File.join("mods", "mods-relateditem-project.xml")) }
      it "should be able to translate the title value" do
        expect(solr_doc["project_key_ssim"]).to include "lindquist"
        expect(solr_doc["project_key_ssim"]).to include "customer_orders"
      end
    end
  end

  describe ".collection_titles" do
    let(:xml_src) { fixture( File.join("mods", "mods-titles.xml")) }
    it "should find the collection titles for faceting" do
      expect(adapter.collection_titles).to eql ['The Pulitzer Prize Photographs']
    end
  end

  describe ".collection_keys" do
    context "the collection in the description has a key" do
      let(:xml_src) { fixture( File.join("mods", "mods-archival-context.xml")) }
      it "should find the collection keys for faceting" do
        expect(adapter.collection_keys).to include '4079753'
        expect(solr_doc["collection_key_ssim"]).to include "4079753"
      end
    end
    context "the collection in the description has no associated keys" do
      let(:xml_src) { fixture( File.join("mods", "mods-titles.xml")) }
      it "should find no collection keys for faceting" do
        expect(adapter.collection_keys).to be_empty
        expect(solr_doc["collection_key_ssim"]).to be_blank
      end
    end
  end

  describe ".shelf_locators" do
    let(:xml_src) { fixture( File.join("mods", "mods-physical-location.xml")) }
    it "should find the shelf locators" do
      expect(solr_doc["lib_shelf_sim"]).to eql ["Box no. 057"]
    end
  end

  describe ".add_shelf_locator_facets!" do
    let(:solr_doc) { Hash.new }
    before { adapter.add_shelf_locator_facets!(solr_doc, input_values) }
    context "simple, regular data" do
      let(:input_values) { ['Box no. 9, Folder no. 4'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['9']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to eql(['4']) }
    end
    context "elaborate text data" do
      let(:input_values) { ['Box no. Vol. XVI. Italian gardens., Folder no. Folder/Page 055, Item no. Image number: 217, AA712 M1953 F'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['Vol. XVI. Italian gardens.']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to eql(['Page 055']) }
    end
    context "multiple separate values for same part" do
      let(:input_values) { ['Box no. 9', 'Box no. 4'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['9','4']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to be_nil }
    end
    context "semicolon joined values" do
      let(:input_values) { ['Box no. 9; 4, Folder no. 12'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['9','4']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to eql(['12']) }
    end
    context "redundant labels" do
      let(:input_values) { ['Box no. Box 9; Box 4, Folder no. folder 12'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['9','4']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to eql(['12']) }
    end
    context "redundant values" do
      let(:input_values) { ['Box no. 9; Box 9'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to eql(['9']) }
      it { expect(solr_doc['lib_shelf_folder_sim']).to be_nil }
    end
    context "no identifiable parts" do
      let(:input_values) { ['NYDA.SHELF.MARK.001'] }
      it { expect(solr_doc['lib_shelf_box_sim']).to be_nil }
      it { expect(solr_doc['lib_shelf_folder_sim']).to be_nil }
    end
  end

  describe ".enumerations" do
    let(:xml_src) { fixture( File.join("mods", "mods-physical-location-with-dual-location-shelflocator-and-sublocation.xml") ) }
    it "parse enumerationAndChronology from copyInformation" do
      expect(solr_doc["lib_enumeration_ssim"].sort).to eql ['v.1-2']
    end
  end

  describe ".textual_dates" do
    let(:xml_src) { fixture( File.join("mods", "mods-textual-dates-with-unusual-chars.xml")) }
    it "should not change the textual date, other than removing leading or trailing whitespace" do
      expect(solr_doc["lib_date_textual_ssm"].sort).to eql ['-12 BCE', 'Circa 1940', '[19]22?']
    end
  end

  describe ".names" do
    let(:xml_src) { fixture( File.join("mods", "mods-names.xml")) }
    it "should find name values and ignore roleTerms" do
      expect(adapter.names).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745', 'Included Without Attribute', 'Dear Brother', 'Seminar 401']
    end
    it "should find name values with authority/role pairs" do
      expect(adapter.names(:marcrelator, 'rcp')).to eql ['Name, Recipient 1829-1745', 'Dear Brother']
    end
    it "should not find subject names" do
      expect(adapter.names).not_to include('Jay, John 1745-1829')
    end
  end

  describe ".add_names_by_text_role!" do
    let(:xml_src) { fixture( File.join("mods", "mods-names.xml")) }
    it "should index names by role" do
      doc = {}
      adapter.add_names_by_text_role!(doc)
      expect(doc).to include({
        'role_addressee_ssim' => ["Name, Recipient 1829-1745", "Dear Brother"],
        'role_owner_agent_ssim' => ["Name, Recipient 1829-1745"]
      })
    end
  end

  describe ".coordinates" do
    let(:xml_src) { fixture( File.join("mods", "mods-subjects.xml")) }
    it "should find coordinate values" do
      expect(adapter.coordinates).to eql ['40.8075,-73.9619', '40.6892,-74.0444', '-40.6892,74.0444', '40.75658174592119,-73.98963708106945']
    end
  end

  describe ".classification_other" do
    it "should find classification values with authority 'z', meaning 'other'" do
      expect(adapter.classification_other).to eql ['AB.CD.EF.G.123', 'AB.CD.EF.G.456']
    end
  end
  describe ".archive_org_identifiers" do
    it "should index an archive.org identifier" do
      expect(adapter.archive_org_identifiers).to eql [
        { id: 'internet_archive_id_value', displayLabel: 'internet_archive_id_label' }
      ]
    end
  end
  describe ".archive_org_identifier" do
    it "should index an archive.org identifier" do
      expect(adapter.archive_org_identifier).to eql 'internet_archive_id_value'
    end
  end
  describe ".archival_context_json" do
    let(:xml_src) { fixture( File.join("mods", "mods-archival-context.xml")) }
    let(:expected) { JSON.load(File.read(fixture( File.join("json", "archival_context.json")))) }
    it "should produce json-ld for the archival context" do
      expect(expected).to include_json(adapter.archival_context_json[0])
    end
    it "should add it to the solr document" do
      expect(adapter.to_solr).to have_key('archival_context_json_ss')
    end
  end
  describe ".copyright_statement" do
    let(:xml_src) { fixture( File.join("mods", "mods-access-condition.xml")) }
    let(:expected) { 'http://rightsstatements.org/vocab/InC/1.0/' }
    it "should index a copyright statement" do
      expect(adapter.copyright_statement).to eql expected
      expect(adapter.to_solr['copyright_statement_ssi']).to eql expected
    end
  end
  describe ".reading_room_locations" do
    let(:xml_src) { fixture( File.join("mods", "mods-site-fields.xml")) }
    let(:expected) { ['info://rbml.library.columbia.edu'] }
    it "should index a copyright statement" do
      expect(adapter.reading_room_locations).to eql expected
      expect(adapter.to_solr['reading_room_ssim']).to eql expected
    end
  end
  describe ".search_scope" do
    let(:xml_src) { fixture( File.join("mods", "mods-site-fields.xml")) }
    let(:expected) { 'project' }
    it "should index a copyright statement" do
      expect(adapter.search_scope).to eql [expected]
      expect(adapter.to_solr['search_scope_ssi']).to eql expected
    end
  end
  describe ".sort_title" do
    let(:xml_src) { fixture( File.join("mods", "mods-titles-extended.xml")) }
    let(:expected) { 'GHOTOGRAPHS ゐ' }
    it "should index a sort title without diacritics, punctuation or case sensitivity" do
      expect(adapter.to_solr['title_si']).to eql expected
    end
  end

  describe ".iiif_properties" do
    let(:xml_src) { fixture( File.join("mods", "mods-iiif-ext.xml")) }
    let(:expected) { {'iiif_behavior_ssim' => ['paged'], 'iiif_viewing_direction_ssi' => 'left-to-right'} }
    it "should index iiif extension properties when present" do
      expect(adapter.iiif_properties).to eql expected
      expect(adapter.to_solr).to have_key('iiif_behavior_ssim')
      expect(adapter.to_solr).to have_key('iiif_viewing_direction_ssi')
    end
    context "are absent" do
      let(:xml_src) { fixture( File.join("mods", "mods-titles-extended.xml")) }
      it "adds no properties" do
        expect(adapter.iiif_properties).to be_empty
      end
    end
  end
  describe "aspace identifiers" do
      let(:xml_src) { fixture( File.join("mods", "mods-aspace-ids.xml")) }
      it "has expected aspace id values" do
        expect(adapter.to_solr).to have_key('archives_space_identifier_ssim')
        expect(adapter.to_solr['archives_space_identifier_ssim']).to eql(['80a20b70974e7d481592b6301618ebaa'])
      end
  end
end
