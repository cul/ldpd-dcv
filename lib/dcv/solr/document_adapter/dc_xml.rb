# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class << self
    # Create a new adapter object
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    # @return [Dcv::Solr::DocumentAdapter::DcXml]
    def DcXml ng_or_string_or_io
      DcXml.new(ng_or_string_or_io)
    end
  end

  class DcXml < Dcv::Solr::DocumentAdapter::Abstract
    DC_NS = {"oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/", "dc"=>"http://purl.org/dc/elements/1.1/"}

    autoload :OmRules, 'dcv/solr/document_adapter/dc_xml/om_rules'
    include OmRules

    attr_accessor :ng_xml

    # Initialize adapter object with nokogiri xml structure
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    def initialize(ng_or_string_or_io)
      @ng_xml = ng_or_string_or_io.is_a?(Nokogiri::XML::Document) ? ng_or_string_or_io : Nokogiri::XML(ng_or_string_or_io)
    end

    def dc
      ng_xml.xpath('/oai_dc:dc', DC_NS).first
    end

    # Create or update a solr document with fields drawn from @ng_xml 
    # @param doc [Hash]
    # @return [Hash]
    def to_solr(doc={})
      super(doc)
    end
  end
end