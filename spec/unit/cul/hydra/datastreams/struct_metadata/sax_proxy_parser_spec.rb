require 'rails_helper'

describe Cul::Hydra::Datastreams::StructMetadata::SaxProxyParser, type: :unit do
  let(:graph_context_uri) { RDF::URI("info:fedora/test:object") }
  let(:nested_seq_fixture) { fixture( File.join("struct_map", "structmap-nested.xml")).read }
  let(:ng_xml) { Nokogiri::XML(nested_seq_fixture) }
  let(:ns_prefix) { 'mets' }
  let(:dom_parser) { Cul::Hydra::Datastreams::StructMetadata::DomProxyParser.new(graph_context_uri: graph_context_uri, ng_xml: ng_xml, ns_prefix: ns_prefix) }
  let(:sax_parser) { described_class.new(graph_context_uri: graph_context_uri, xml_io: nested_seq_fixture, ns_prefix: ns_prefix) }
  let(:expected) do
    dom_parser.proxies.map(&:to_solr).sort { |x, y| x['id'] <=> y['id'] }
  end
  let(:actual) do
    sax_parser.proxy_enumerator.to_a.sort { |x, y| x['id'] <=> y['id'] }
  end
  it "produces the same solr data as the DOM parser" do
    expect(actual[0]).to eq(expected[0])
    expect(actual).to eq(expected)
  end

  skip "works on a really big file" do
    actual = true
    expected = false
    open("tmp/large-structMetadata.xml", 'rb', external_encoding: Encoding::UTF_8) do |io|
      actual = 0
      s = Time.now
      Cul::Hydra::Datastreams::StructMetadata::SaxProxyParser.new(
        graph_context_uri: graph_context_uri, xml_io: io, ns_prefix: ns_prefix
      ).each {|x| actual += 1}
      e = Time.now
      puts "sax parsing: #{actual} in #{e - s}"
    end
    open("tmp/large-structMetadata.xml", 'rb', external_encoding: Encoding::UTF_8) do |io|
      _ng_xml = Nokogiri::XML(io)
      s = Time.now
      expected = 0
      Cul::Hydra::Datastreams::StructMetadata::DomProxyParser.new(
        graph_context_uri: graph_context_uri, ng_xml: _ng_xml, ns_prefix: ns_prefix
      ).proxies.each {|x| expected += 1}
      e = Time.now
      puts "dom parsing: #{expected} in #{e - s}"
    end
    expect(actual).to eql(expected)
  end
end