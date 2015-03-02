class DurstController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
  end

  def index
    super
    unless has_search_parameters?
      render 'home'
    end
  end

  def map_search
    # Special logic for map search.  Need to pull in ALL records.

    @response = Rails.cache.fetch('map_data_response')
    @document_list = Rails.cache.fetch('map_data_document_list')

    if @response.nil?
      #Rails.logger.info('Retrieving and caching Durst map data.')
      (@response, @document_list) = get_search_results(params, {:rows => 100000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}) # Calling get_search_results manually so that we always plot all points for the home page map
      cache_expiration_time = 10.minutes
      Rails.cache.write('map_data_response', @response, expires_in: cache_expiration_time)
      Rails.cache.write('map_data_document_list', @document_list, expires_in: cache_expiration_time)
    end

  end

end
