module Dcv::MapDataController
  extend ActiveSupport::Concern

  def map_search
  end

  def map_response_params
    {:rows => 200000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}
  end

  def set_map_data_json
    if has_search_parameters?
      map_cache_key = subsite_key + '_map_search_data_json?'
      params.sort {|a,b| a[0] <=> b[0] }.each do |k, v|
        if k.starts_with?('f[') || k.eql?('q')
          map_cache_key << '&' unless map_cache_key[-1] == '?'
          map_cache_key << k << '=' << v
        end
      end
    else
      map_cache_key = subsite_key + '_map_search_data_json'
    end
    @map_data_json = Rails.cache.fetch(map_cache_key)
    if @map_data_json.nil?
      search_params = params.merge('f[coordinates][]' => '*')
      (@response, @document_list) = get_search_results(search_params, map_response_params) # Calling get_search_results manually so that we always plot all points for the home page map
      cache_expiration_time = Rails.env.development? ? 5.minutes : 1.day
      map_data = extract_map_data_from_document_list(@document_list)
      @map_data_json = map_data.to_json
      Rails.cache.write(map_cache_key, @map_data_json, expires_in: cache_expiration_time)
    end
  end
end
