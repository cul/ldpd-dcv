module Dcv::SolrHelper
  include Dcv::AccessLevels

  def access_control_fields(solr_doc = {})
    SolrDocument::ACCESS_CONTROL_FIELDS.map { |field_name| [field_name, solr_doc[field_name]] }.to_h.compact
  end

  def can_access_asset?(solr_doc = {}, ability = nil)
    solr_doc = SolrDocument.new(solr_doc) unless solr_doc.is_a? SolrDocument
    ability ? ability.can?(Ability::ACCESS_ASSET, solr_doc) : can?(Ability::ACCESS_ASSET, solr_doc)
  end

  def online_access_indicated?(hash)
    (hash['access_control_levels_ssim'] & [ACCESS_LEVEL_CLOSED, ACCESS_LEVEL_EMBARGO]).blank?
  end

  def online_access_filters
    [ACCESS_LEVEL_CLOSED, ACCESS_LEVEL_EMBARGO].map {|val| "!access_control_levels_ssim:\"#{val}\""}
  end
end