module Dcv::Sites::SearchableController
  def default_search_mode
    search_config = load_subsite&.search_configuration
    search_config ? search_config.display_options.default_search_mode : :grid
  end

  def default_search_mode_cookie
    slug = load_subsite&.slug || controller_path
    cookie_name = "#{slug}_search_mode"
    cookie_name.gsub!('/','_')
    cookie_name = cookie_name.to_sym
    cookie = cookies[cookie_name]
    unless cookie
      cookies[cookie_name] = default_search_mode.to_sym
    end
  end

  # We want this data to be as compact as possible because we're sending a lot to the client
  # TODO: Move to Dcv::MapDataController
  def extract_map_data_from_document_list(document_list)

    max_title_length = 50

    map_data = []
    document_list.each do |document|
      if document['geo'].present?
        document['geo'].each do |coordinates|

          lat_and_long = coordinates.split(',')

          is_book = document['lib_format_ssm'].present? && document['lib_format_ssm'].include?('books')

          title = document['title_display_ssm'][0].gsub(/\s+/, ' ') # Compress multiple spaces and new lines into one
          title = title[0,max_title_length].strip + '...' if title.length > max_title_length

          row = {
            id: document.id,
            c: lat_and_long[0].strip + ',' + lat_and_long[1].strip,
            t: title,
            b: is_book ? 'y' : 'n',
          }

          map_data << row
        end
      end
    end

    return map_data
  end

  def controller
    self
  end
end