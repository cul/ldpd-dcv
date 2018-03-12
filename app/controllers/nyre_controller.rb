class NyreController < SubsitesController

  before_action :set_map_data_json, only: [:map_search]
  #before_action :set_map_data_json, only: [:index, :map_search]

  configure_blacklight do |config|
    Dcv::Configurators::NyreBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    if request.format.csv?
      stream_csv_response_for_search_results
    else
  	  super
      unless has_search_parameters?
        render 'home'
      end
    end
  end

  def map_search
  end

  def about
  end

  private

  def set_map_data_json
    unless has_search_parameters?
      map_cache_key = subsite_key + '_map_search_data_json'
      @map_data_json = Rails.cache.fetch(map_cache_key)
      if @map_data_json.nil?
        (@response, @document_list) = get_search_results(params, {:rows => 200000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}) # Calling get_search_results manually so that we always plot all points for the home page map
        cache_expiration_time = Rails.env.development? ? 5.minutes : 1.day
        map_data = extract_map_data_from_document_list(@document_list)
        @map_data_json = map_data.to_json
        Rails.cache.write(map_cache_key, @map_data_json, expires_in: cache_expiration_time)
      end
    end
  end

end
