module Dcv::MapDataHelper

  #def get_map_data_for_document_list(document_list)
  #
  #  start_time = Time.now
  #
  #  coordinate_output = []
  #  document_list.each do |document|
  #    if document['geo'].present?
  #      document['geo'].each do |coordinates|
  #        lat_and_long = coordinates.split(',')
  #
  #        if document['lib_format_ssm'].present? && document['lib_format_ssm'].include?('books')
  #          image_url_for_document = image_url('book-placeholder.png')
  #        else
  #          image_url_for_document = get_asset_url(id: document.id, size: 256, type: 'featured', format: 'jpg')
  #        end
  #
  #        row = {
  #          lat: lat_and_long[0].strip, long: lat_and_long[1].strip, title: document['title_display_ssm'][0],
  #          thumbnail_url: image_url_for_document,
  #          item_link: '/durst/' + document.id
  #        }
  #        coordinate_output << row
  #      end
  #    end
  #  end
  #
  #  puts 'Processed and formatted map data in ' + (Time.now - start_time).to_s + ' seconds'
  #
  #  return coordinate_output
  #end

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
    return false unless solr_response
    solr_response[:facet_counts][:facet_fields][:has_geo_bsi].tap do |has_geo_bsi|
      return false if has_geo_bsi.blank?
      return has_geo_bsi[1] > 0 if has_geo_bsi[0] == 'true' 
      return has_geo_bsi[3] > 0 if has_geo_bsi[2] == 'true'
    end
    return false
  end

  def should_render_location_data?(document={})
    (geo_facet_fields_to_show + geo_non_facet_fields_to_show).detect do |field|
      document[field.field].present?
    end
  end
end
