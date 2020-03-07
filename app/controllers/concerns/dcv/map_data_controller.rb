module Dcv::MapDataController
  extend ActiveSupport::Concern

  def map_search
  end

  def map_response_params
    {:rows => 200000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}
  end

  def set_map_data_json
    if has_search_parameters? && (params[:q].present? || params[:f].present?)
      map_cache_key = subsite_key + '_map_search_data_json?q=' + params[:q].to_s

      params.fetch(:f, []).sort {|a,b| a[0] <=> b[0] }.each do |k, vals|
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
