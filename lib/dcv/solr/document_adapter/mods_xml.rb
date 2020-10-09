# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class << self
    # Create a new adapter object
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    # @return [Dcv::Solr::DocumentAdapter::ModsXml]
    def ModsXml ng_or_string_or_io
      ModsXml.new(ng_or_string_or_io)
    end
  end

  class ModsXml < Dcv::Solr::DocumentAdapter::Abstract
    MODS_NS = {'mods'=>'http://www.loc.gov/mods/v3', 'cul' => 'http://id.library.columbia.edu/property/'}

    autoload :OmRules, 'dcv/solr/document_adapter/mods_xml/om_rules'
    autoload :Fields, 'dcv/solr/document_adapter/mods_xml/fields'
    include OmRules # to mimic ActiveFedora/OM behavior, this is included before Fields
    include Fields

    attr_accessor :ng_xml

    # Initialize adapter object with nokogiri xml structure
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    def initialize(ng_or_string_or_io)
      @ng_xml = ng_or_string_or_io.is_a?(Nokogiri::XML::Document) ? ng_or_string_or_io : Nokogiri::XML(ng_or_string_or_io)
    end


    def mods
      ng_xml.xpath('/mods:mods', MODS_NS).first
    end

    # Create or update a solr document with fields drawn from @ng_xml 
    # @param doc [Hash]
    # @return [Hash]
    def to_solr(doc={})
      super(doc)
    end
  end
end