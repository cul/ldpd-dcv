module Dcv::SolrHelper
  def accessControlFields(solr_doc = {})
    {
      'access_control_affiliations_ssim' => solr_doc['access_control_affiliations_ssim'],
      'access_control_locations_ssim' => solr_doc['access_control_locations_ssim'],
      'access_control_embargo_dtsi' => solr_doc['access_control_embargo_dtsi'],
      'access_control_permissions_bsi' => solr_doc['access_control_permissions_bsi'],
      'access_control_levels_ssim' => solr_doc['access_control_levels_ssim'],
    }.compact
  end

  def can_access_asset?(solr_doc = {})
  	solr_doc = SolrDocument.new(solr_doc) unless solr_doc.is_a? SolrDocument
  	can?(Ability::ACCESS_ASSET, solr_doc)
  end

  def online_access_indicated?(hash)
     (hash['access_control_levels_ssim'] & ['Closed', 'Embargoed']).blank?
  end
end