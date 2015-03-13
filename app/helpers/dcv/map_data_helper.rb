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
  #          image_url_for_document = get_asset_url(id: document.id, size: 256, type: 'square', format: 'jpg')
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

end
