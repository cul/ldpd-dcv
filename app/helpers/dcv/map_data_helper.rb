module Dcv::MapDataHelper
  def geo_facet_fields_to_show
    blacklight_config.geo_fields.select {|f,v| v.link }.map {|f,v| v}
  end

  def geo_non_facet_fields_to_show
    blacklight_config.geo_fields.select {|f,v| !v.link }.map {|f,v| v}
  end

  def has_geo?(document={},coords_only=false)
    if coords_only
      document['geo']
    else
      document['geo'] || should_render_location_data?(document)
    end
  end

  def has_geo_facet?(solr_response=@response)
    geo_facet_count(solr_response, true) > 0
  end

  def geo_facet_count(solr_response=@response, value=true)
    return 0 unless solr_response
    solr_response[:facet_counts][:facet_fields][:has_geo_bsi].tap do |has_geo_bsi|
      return 0 if has_geo_bsi.blank?
      return has_geo_bsi[1] if has_geo_bsi[0] == value.to_s 
      return has_geo_bsi[3] if has_geo_bsi[2] == value.to_s
    end
    return 0
  end

  def should_render_location_data?(document={})
    (geo_facet_fields_to_show + geo_non_facet_fields_to_show).detect do |field|
      document[field.field].present?
    end
  end
end
