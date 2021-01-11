class CatalogController < SubsitesController
  include Dcv::DigitalProjectsController
  include Dcv::Catalog::BrowseListBehavior

  before_action :get_catalog_browse_lists, only: [:home, :browse]

  def search_builder
    super.tap { |builder| builder.processor_chain.concat [:hide_concepts_when_query_blank_filter] }
  end
  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config, true)
  end

  def subsite_layout
    'gallery'
  end

  def home_params
    {
      fq: [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:Concept',
        'dc_type_sim:"Publish Target"',
        '-slug_ssim:(sites OR catalog)' # Do not include sites or catalog publish target in this list
      ],
      sort: "title_si asc",
      qt: 'search',
      rows: 250
    }
  end

  # get search results from the solr index forhome page
  def home
    @response = repository.search(home_params)
    @document_list = @response.documents

    respond_to do |format|
      format.html { render action: 'home' }
    end
  end

end
