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
    (@response, @document_list) = get_search_results(params, {:rows => 100000}) # Calling get_search_results manually so that we always plot all points for the home page map
  end

end
