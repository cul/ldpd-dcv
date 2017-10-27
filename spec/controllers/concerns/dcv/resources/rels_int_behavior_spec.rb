require 'rails_helper'

describe Dcv::Resources::RelsIntBehavior, type: :unit do
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
  describe '#resources_for_document' do
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
end
