# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class << self
    # Create a new adapter object
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    # @return [Dcv::Solr::DocumentAdapter::XacmlXml]
    def XacmlXml ng_or_string_or_io
      XacmlXml.new(ng_or_string_or_io)
    end
  end

  class XacmlXml < Dcv::Solr::DocumentAdapter::Abstract
    XACML_NS = {'xacml'=>'urn:oasis:names:tc:xacml:3.0:core:schema:wd-17'}

    autoload :Fields, 'dcv/solr/document_adapter/xacml_xml/fields'
    include Fields

    attr_accessor :ng_xml

    # Initialize adapter object with nokogiri xml structure
    # @param ng_or_string_or_io [Nokogiri::XML|String|IO]
    def initialize(ng_or_string_or_io)
      @ng_xml = ng_or_string_or_io.is_a?(Nokogiri::XML::Document) ? ng_or_string_or_io : Nokogiri::XML(ng_or_string_or_io)
    end

    def xacml
      ng_xml.xpath('/xacml:Policy', XACML_NS).first
    end

    # Create or update a solr document with fields drawn from @ng_xml 
    # @param doc [Hash]
    # @return [Hash]
    def to_solr(doc={})
      solr_doc = (defined? super) ? super : solr_doc

      return solr_doc if xacml.nil?  # Return because there is nothing to process
      solr_doc['access_control_levels_ssim'] = access_levels
      solr_doc['access_control_permissions_bsi'] = permissions_indicated?
      solr_doc['access_control_embargo_dtsi'] = permit_after_date
      solr_doc['access_control_affiliations_ssim'] = permit_affiliations
      solr_doc['access_control_locations_ssim'] = permit_locations

      solr_doc['access_control_levels_ssim'] ||= [Dcv::AccessLevels::ACCESS_LEVEL_PUBLIC]
      solr_doc['access_control_permissions_bsi'] = !!solr_doc['access_control_permissions_bsi']
      solr_doc
    end
  end
end