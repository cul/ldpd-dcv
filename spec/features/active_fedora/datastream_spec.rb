require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require 'digest'
# this is a test suite ported from cul_hydra
describe ActiveFedora::Datastream, type: :integration do
  before :all do
    rubydora_connection() # init ActiveFedora
  end
  let(:test_obj) {
    ActiveFedora::Base.new(pid:"test:ds")
  }
  let(:ds_location) {
    'file:' + absolute_fixture_path(File.join("mods", "mods-001.xml"))
  }
  let(:ds_content) {
    dsc = ''
    fixture(File.join("mods", "mods-001.xml")).read(nil,dsc)
    dsc
  }
  let(:ds_checksum) {
    Digest::MD5.hexdigest(ds_content)
  }
  let(:ds_format_uri) {
    "http://cul.info/types/fake"
  }
  before do
    test_obj.save
  end
  after do
    test_obj.delete
  end
  it "should allow defintion of the format URI" do
      ds = test_obj.create_datastream(ActiveFedora::Datastream, "external", controlGroup: 'E', dsLocation:ds_location)
      ds.formatURI = ds_format_uri
      test_obj.add_datastream(ds)
      test_obj.save
      searched = ActiveFedora::Base.find(test_obj.pid)
      expect(searched.datastreams['external'].formatURI).to eql(ds_format_uri)
  end
  context "External Datastream Content" do
    it "should be taggable with a documentary checksum" do
      pending "docker external file locations"
      ds = test_obj.create_datastream(ActiveFedora::Datastream, "external", controlGroup: 'E', dsLocation:ds_location)
      ds.checksum = ds_checksum()
      ds.checksumType = 'MD5'
      test_obj.add_datastream(ds)
      test_obj.save
      searched = ActiveFedora::Base.find(test_obj.pid)
      expect(searched.datastreams['external'].checksum).to eql(ds_checksum)
    end
  end
end