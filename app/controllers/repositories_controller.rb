require 'redcarpet'

class RepositoriesController < SitesController
  include Dcv::Sites::ReadingRooms

  layout Proc.new { |controller| 'gallery' }

  configure_blacklight do |config|
    config.search_state_fields << :repository_id # allow repository id for routing
    Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config, search_bar: Dcv::SearchBar::RepositoriesComponent)
  end

  before_action :set_repository_id, only:[:show]
  before_action :load_subsite, only:[:show, :about, :reading_room]

  prepend_view_path('app/views/repositories')

  def initialize(*args)
    super(*args)
    self._prefixes.unshift 'repositories'
  end

  def load_subsite
    @subsite ||= begin
      site_slug = params[:repository_id]
      s = Site.includes(:nav_links).find_by(slug: site_slug)
      s&.configure_blacklight!
      s
    end
  end

  def subsite_key
    params[:repository_id] || load_subsite&.slug
  end

  def search_service_context
    { builder: { addl_processor_chain: [:constrain_to_repository_context] } }
  end

  def set_repository_id
    params[:repository_id] = params[:id] # routing hack for sanity in the partials
  end

  ##
  # If the current action should start a new search session, this should be
  # set to true
  # see also Blacklight::Catalog::SearchContext
  def start_new_search_session?
    true
  end

  def digital_projects(restricted = false)
    unless @document_list
      (@response, @document_list) = search_results(params)
    end
    @digital_projects ||= @document_list.map do |solr_doc|
      t = {
        id: solr_doc.id,
        name: strip_restricted_title_qualifier(solr_doc.fetch('title_ssm',[]).first),
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.fetch('source_ssim',[]).first, # TODO: Handle landing page sites in this context
        description: solr_doc.fetch('abstract_ssim',[]).first,
        search_scope: solr_doc.fetch('search_scope_ssi', "project") || "project"
      }
      t[:facet_value] = solr_doc.fetch('short_title_ssim',[]).first if published_to_catalogs?(solr_doc)
      t[:facet_field] = (t[:search_scope] == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
      unless t[:external_url]
        t[:external_url] = solr_doc[:restriction_ssim].present? ? restricted_site_url(solr_doc.fetch('slug_ssim',[]).first) : site_url(solr_doc.fetch('slug_ssim',[]).first)
      end
      t
    end
  end

  def strip_restricted_title_qualifier(qualified_title)
    unqualified_title = qualified_title.dup
    unqualified_title.sub!(/\s*[\[\(]Restricted[\)\]]\s*/i, '')
    unqualified_title
  end

  def published_to_catalogs?(document={})
    document && (document.fetch('publisher_ssim',[]) & catalog_uris).present?
  end

  def catalog_uris
    ['restricted', 'public'].map { |top| SUBSITES[top].fetch('catalog',{})['uri'] }.compact
  end

  def site_uri(restricted = false)
    top = restricted ? 'restricted' : 'public'
    SUBSITES[top].fetch('sites',{})['uri']
  end

  def subsite_layout
    'gallery'
  end

  def subsite_styles
    ["#{subsite_layout}-#{Dcv::Sites::Constants.default_palette}", "catalog"]
  end

  def show
    redirect_to repository_reading_room_path(repository_id: params[:id])
  end

  def reading_room
    template_key = params[:repository_id].downcase
    template_key.gsub!("-","")
    render "reading_room"
  end

  def about
    template_key = params[:repository_id].downcase
    template_key.gsub!("-","")
    render "reading_room/#{template_key}/about"
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  # see also HomeController
  def search_action_url options = {}
    url_for(options.merge(:action => 'index', :controller=>'catalog'))
  end
end
