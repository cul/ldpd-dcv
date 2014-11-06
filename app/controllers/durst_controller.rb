class DurstController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
  end

  def index
    if has_search_parameters?
      super
    else
      # Special logic for home page.  This is temporary.
      # Once we have a lot of records in solr, we'll want to do the home page
      # map query via ajax request to a different controller action.
      (@response, @document_list) = get_search_results(params, {:rows => 100000}) # Calling get_search_results manually so that we always plot all points for the home page map
      respond_to do |format|
        format.html { }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
        format.json do
          render json: render_search_results_as_json
        end
        additional_response_formats(format)
        document_export_formats(format)
      end
      render 'home'
    end
  end

end
