module Dcv::SolrHelper
  def access_control_fields(solr_doc = {})
    SolrDocument::ACCESS_CONTROL_FIELDS.map { |field_name| [field_name, solr_doc[field_name]] }.to_h.compact
  end

  def can_access_asset?(solr_doc = {})
  	solr_doc = SolrDocument.new(solr_doc) unless solr_doc.is_a? SolrDocument
  	can?(Ability::ACCESS_ASSET, solr_doc)
  end

  def online_access_indicated?(hash)
     (hash['access_control_levels_ssim'] & ['Closed', 'Embargoed']).blank?
  end
end