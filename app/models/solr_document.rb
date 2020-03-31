# -*- encoding : utf-8 -*-
class SolrDocument

  ACCESS_CONTROL_FIELDS = [
    'access_control_affiliations_ssim',
    'access_control_locations_ssim',
    'access_control_embargo_dtsi',
    'access_control_permissions_bsi',
    'access_control_levels_ssim'
  ]

  include Blacklight::Solr::Document

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)

  # Item in context url for this solr document. Might return nil if this doc has no item in context url.
  def item_in_context_url
    self['lib_item_in_context_url_ssm'].present? ? self['lib_item_in_context_url_ssm'].first : nil
  end

  def site_result?
    self['dc_type_ssm'].present? && self['dc_type_ssm'].include?('Publish Target')
  end
end
