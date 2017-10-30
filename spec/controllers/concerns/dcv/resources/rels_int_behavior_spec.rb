require 'rails_helper'

describe Dcv::Resources::RelsIntBehavior, type: :unit do
  describe '#resources_for_document' do
    let(:test_class) do
      Class.new(ApplicationController) do
        include Dcv::Resources::RelsIntBehavior
        def url_for_content(key, dsLabel, mime)
          'localhost/' + key
        end
      end
    end
    let(:document) do
      props = YAML.load(fixture('yml/bytestreams.yml').read)
      doc = {}
      props.each do |k, v|
        # put multiple value fields in an array, like we'd get from rsolr
        v = JSON.dump(v) if v.is_a? Hash
        doc[k] = (k =~ /m$/) ? [v] : v
      end
      SolrDocument.new(doc)
    end
    subject do
      test_class.new
    end
    let(:resource_keys) { subject.resources_for_document(document).collect {|x| x[:id] } }
    it "returns a list of datastreams that are content-bearing datastream" do
      # it should link reformats indicated in RELS-INT
      expect(resource_keys).to include('file-reformat')
      # it should link other apparently content-bearing datastreams
      expect(resource_keys).to include('thumbnail')
      # the test object is an image, so don't link original
      expect(resource_keys).not_to include('content')
      # internal datastreams are explicitly excluded
      expect(resource_keys).not_to include('RELS-EXT')
      # metadata datastreams are explicitly excluded
      expect(resource_keys).not_to include('descMetadata')
      # jp2 datastreams are explicitly excluded
      expect(resource_keys).not_to include('zoom')
    end
  end
  describe '#url_for_content' do
    let(:test_class) do
      Class.new(ApplicationController) do
        include Dcv::Resources::RelsIntBehavior
      end
    end
    subject do
      test_class.new
    end
    it "gets the expected mp3 file extension when dsLabel has a .mp3 extension and mime value is an empty string" do
      expect(subject).to receive(:bytestream_content_url).with({catalog_id: 'abc:123', bytestream_id: 'access', format: 'mp3'})
      subject.url_for_content('catalog/abc:123/access', 'access.mp3', '')
    end

    it "gets the expected mp3 file extension when dsLabel has a .mp3 extension an mp3's audio/mpeg mime value is present" do
      expect(subject).to receive(:bytestream_content_url).with({catalog_id: 'abc:123', bytestream_id: 'access', format: 'mp3'})
      subject.url_for_content('catalog/abc:123/access', 'access.mp3', 'audio/mpeg')
    end

    it "gets the expected file extension when dsLabel has no extension and mime value is present for a wav file" do
      expect(subject).to receive(:bytestream_content_url).with({catalog_id: 'abc:123', bytestream_id: 'content', format: 'wav'})
      subject.url_for_content('catalog/abc:123/content', 'content', 'audio/x-wav')
    end

    it "gets the 'bin' extension when dsLabel has no extension and mime value is not present" do
      expect(subject).to receive(:bytestream_content_url).with({catalog_id: 'abc:123', bytestream_id: 'content', format: 'bin'})
      subject.url_for_content('catalog/abc:123/content', 'content', '')
    end
  end
end
