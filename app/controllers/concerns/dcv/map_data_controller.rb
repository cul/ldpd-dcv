module Dcv::MapDataController
  extend ActiveSupport::Concern

  def map_search
  end

  def map_response_params
    {:rows => 200000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}
  end

  # We want this data to be as compact as possible because we're sending a lot to the client
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

  def set_map_data_json
    if has_search_parameters? && (params[:q].present? || params[:f].present?)
      map_cache_key = subsite_key + '_map_search_data_json?q=' + params[:q].to_s

      params.permit(:f).fetch(:f, []).sort {|a,b| a[0] <=> b[0] }.each do |k, vals|
          vals.sort.each { |val| map_cache_key << '&' << k << '=' << val }
      end
    else
      map_cache_key = subsite_key + '_map_search_data_json'
    end
    @map_data_json = Rails.cache.fetch(map_cache_key)
    if @map_data_json.nil?
      extra_controller_params = map_response_params
      extra_controller_params[:f] = (params[:f].present? ? params[:f].dup : {})
      extra_controller_params[:f][:geo] ||= ['*']
      # Calling search_results manually so that we always plot all points for the home page map
      (@response, @document_list) = search_results(params) { |builder| builder.merge extra_controller_params }
      cache_expiration_time = Rails.env.development? ? 5.minutes : 1.day
      map_data = extract_map_data_from_document_list(@document_list)
      @map_data_json = map_data.to_json
      Rails.cache.write(map_cache_key, @map_data_json, expires_in: cache_expiration_time)
    end
  end
end
