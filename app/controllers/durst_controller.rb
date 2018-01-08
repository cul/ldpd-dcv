class DurstController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    super
    unless has_search_parameters?
      render 'home'
    end
  end

  def map_search
    map_cache_key = subsite_key + '_map_search_data_json'
    @map_data_json = Rails.cache.fetch(map_cache_key)
    if @map_data_json.nil?
      (@response, @document_list) = get_search_results(params, {:rows => 100000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}) # Calling get_search_results manually so that we always plot all points for the home page map
      cache_expiration_time = Rails.env.development? ? 5.minutes : 1.day
      map_data = extract_map_data_from_document_list(@document_list)
      @map_data_json = map_data.to_json
      Rails.cache.write(map_cache_key, @map_data_json, expires_in: cache_expiration_time)
    end
  end

  def help
  end

  def favorites
    redirect_to '/durst?durst_favorites=true&search_field=all_text_teim'
  end

  def about_the_collection
  end

  def about_the_project
  end

  def acknowledgements
  end

  def old_york_library_collection_categories
  end

end
