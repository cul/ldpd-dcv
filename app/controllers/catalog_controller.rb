class CatalogController < SubsitesController
  include Dcv::DigitalProjectsController
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Sites::LookupController

  before_action :get_catalog_browse_lists, only: [:home, :browse]

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config, true)
    config.add_facet_field 'content_availability', label: 'Limit by Availability', show: false,
      query: {
        onsite: { label: 'Reading Room', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}!access_control_levels_ssim:Public*" },
        public: { label: 'Public', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}access_control_levels_ssim:Public*" },
      }

    config.home.featured_items_component = Dcv::Catalog::ProjectListComponent
  end

  def search_service_context
    { builder: { addl_processor_chain: [:hide_concepts_when_query_blank_filter] } }
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
      sort: "title_si asc, lib_date_dtsi desc",
      qt: 'search',
      rows: 250
    }
  end

  def setup_show_document
    super
    return unless @document
    scope_candidates = scope_candidates_for(@document)
    return if scope_candidates.blank?
    site_candidates = site_candidates_for(scope_candidates).where.not(id: load_subsite)
    other_sites_data = site_matches_for(@document, site_candidates)
    @document.merge_source!({ other_sites_data: other_sites_data }) if other_sites_data.present?
  end

  # get search results from the solr index forhome page
  def home
    respond_to do |format|
      format.html { render action: 'home' }
    end
  end

  def digital_projects
    @response = search_service.repository.search(home_params)
    @document_list = @response.documents
    super
  end

  # produce a lazily-loaded list of featured items according to a supplied filter
  def featured_items(args= {})
    digital_projects
  end
end
