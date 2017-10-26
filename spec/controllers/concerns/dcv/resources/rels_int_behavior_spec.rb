require 'rails_helper'

describe Dcv::Resources::RelsIntBehavior, type: :unit do
  let(:test_class) do
    Class.new(ApplicationController) do
      include Dcv::Resources::RelsIntBehavior
      def url_for_content(key, mime)
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
    it "returns a list of datastreams that are formats of the content datastream" do
      expect(resource_keys).to include('content')
      expect(resource_keys).to include('info:fedora/demo:1/file-reformat')
      # jp2 datastreams are explicitly excluded
      expect(resource_keys).not_to include('info:fedora/demo:1/zoom')
    end
  end
end
