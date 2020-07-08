require 'redcarpet'

class SitesController < ApplicationController
  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::CdnHelper
  include Dcv::MarkdownRendering
  include ShowFieldDisplayFieldHelper

  before_filter :browse_lists, only: :index
  before_filter :load_subsite, except: [:index]
  before_filter :load_page, only: [:home]

  layout :request_layout

  configure_blacklight do |config|
    config.default_solr_params = {
      :fq => [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:Concept',
        'dc_type_sim:"Publish Target"',
        '-slug_ssim:sites', # Do not include sites publish targets in this list
      ],
      :sort => "title_si asc",
      :qt => 'search'
    }

    config.default_per_page = 250
    config.per_page = [20,60,100,250]
    config.max_per_page = 250

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
    config.index.display_type_field = ActiveFedora::SolrService.solr_name('active_fedora_model', :stored_sortable)
    config.index.thumbnail_method = :thumbnail_for_doc
    config.add_index_field ActiveFedora::SolrService.solr_name('abstract', :symbol, type: :string), :label => 'Abstract'
    config.add_index_field ActiveFedora::SolrService.solr_name('schema_image', :symbol, type: :string), :label => 'Representative Image'
    config.add_index_field ActiveFedora::SolrService.solr_name('short_title', :symbol, type: :string), :label => 'Facet Value'
    config.add_index_field ActiveFedora::SolrService.solr_name('slug', :symbol, type: :string), :label => 'Slug'
    config.add_index_field ActiveFedora::SolrService.solr_name('source', :symbol, type: :string), :label => 'Site URL'
    config.add_index_field ActiveFedora::SolrService.solr_name('title', :symbol, type: :string), :label => 'Title'

    config.show.title_field = solr_name('title_display', :displayable, type: :string)
    config.add_show_field ActiveFedora::SolrService.solr_name('description', :displayable, type: :string), :label => 'Description'
    config.add_show_field ActiveFedora::SolrService.solr_name('schema_image', :symbol, type: :string), :label => 'Representative Image'
    config.add_show_field ActiveFedora::SolrService.solr_name('short_title', :symbol, type: :string), :label => 'Facet Value'
    config.add_show_field ActiveFedora::SolrService.solr_name('slug', :symbol, type: :string), :label => 'Slug'
    config.add_show_field ActiveFedora::SolrService.solr_name('source', :symbol, type: :string), :label => 'Site URL'
    config.add_show_field ActiveFedora::SolrService.solr_name('title', :symbol, type: :string), :label => 'Title'
    config.add_sort_field 'title_si asc', :label => 'title'

    # All Text search configuration, used by main search pulldown.
    config.add_search_field ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text) do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)]
      }
    end
  end

  def search_builder
    super.tap do |builder|
      builder.processor_chain << :constrain_to_slug
      builder.processor_chain <<  (self.restricted? ? :constrain_to_restricted_sites : :constrain_to_public_sites)
    end
  end

  def index
    respond_to do |format|
      format.json {
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET'
        (@response, @document_list) = search_results(params)
        render json: digital_projects
      }
      format.any { super }
    end
  end

  def initialize(*args)
    super(*args)
    self._prefixes.unshift 'shared'
    self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
  end

  def set_view_path
    super
    self.prepend_view_path('app/views/shared')
    self.prepend_view_path('app/views/' + self.request_layout)
    self.prepend_view_path('app/views/' + controller_path)
  end

  ##
  # If the current action should start a new search session, this should be
  # set to true
  # see also Blacklight::Catalog::SearchContext
  def start_new_search_session?
    true
  end

  def load_subsite
    @subsite ||= begin
      site_slug = params[:site_slug] || params[:slug]
      site_slug = "restricted/#{site_slug}" if restricted?
      s = Site.includes(:nav_links).find_by(slug: site_slug)
      s.configure_blacklight! if s
      s
    end
  end

  def load_page
    @page ||= load_subsite.site_pages.includes(:site_text_blocks).find_by(slug: 'home')
  end

  def request_layout
    if (action_name == 'index')
      'dcv' # legacy behavior
    else
      subsite_layout
    end
  end

  def subsite_config
    if action_name == 'index'
      @subsite_config = {}
    else
      @subsite_config ||= load_subsite.to_subsite_config
    end
  end

  def subsite_layout
    subsite_config['layout'] || 'portrait'
  end

  def subsite_styles
    palette = subsite_config['palette'] || 'monochromeDark'
    palette.present? ? "#{subsite_layout}-#{palette}" : subsite_layout
  end

  # get single document from the solr index
  # override to use :slug and publisher_ssim in search to get document
  def home
    document_list = search_results(params)[1] # do not store response or list as attributes
    @document = document_list.first
    if @document.nil?
      render status: :not_found, text: "#{params[:slug]} is not a subsite"
      return
    end
    # override the blacklight config to support featured content and facets
    @blacklight_config = load_subsite.blacklight_config
    # TODO: load facet data. Requires configuration of fields, and override of default solr params.
    respond_to do |format|
      format.json { render json: @subsite.to_json }
      format.html { render }
    end
  end

  # produce a list of featured items according to a supplied filter
  def featured_items(args= {})
    (@response, @document_list) = search_results(params) {|builder| builder.merge(site_search_params(rows: 12))}
    @document_list
  end

  # load facet response
  def load_facet_response
    @response ||= begin
      results = search_results(params) do |builder|
        sites_processor_chain = [:constrain_to_slug, :constrain_to_public_sites, :constrain_to_restricted_sites]
        builder.except(*sites_processor_chain).merge(rows: 0)
      end
      results[0] # do not store list as attribute
    end
    # delete facet responses with only one value-count pair
    @response.dig('facet_counts', 'facet_fields')&.delete_if {|k, v| v.length < 3}
    @response
  end

  # solr params for site content
  def site_search_params(args = {})
      result = load_subsite.blacklight_config.default_solr_params.merge(sort: "random_#{Random.new_seed} DESC")
      result.merge(args)
  end

  # used in :index action
  def digital_projects
    @document_list.delete_if{|doc| doc['source_ssim'].blank? && doc['slug_ssim'].blank? }.each.map do |solr_doc|
      t = {
        name: solr_doc.fetch('title_ssm',[]).first,
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.fetch('source_ssim',[]).first || site_url(solr_doc.fetch('slug_ssim',[]).first),
        description: solr_doc.fetch('abstract_ssim',[]).first,
        search_scope: solr_doc.fetch('search_scope_ssi', "project") || "project"
      }
      t[:facet_value] = solr_doc.fetch('short_title_ssim',[]).first if published_to_catalog?(solr_doc)
      t[:facet_field] = (t[:search_scope] == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
      t
    end
  end

  def published_to_catalog?(document={})
    document && document.fetch('publisher_ssim',[]).include?(catalog_uri)
  end

  def catalog_uri
    SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  # see also HomeController
  def search_action_url(options = {})
    if action_name == 'index'
      url_for(action: 'index', controller: 'catalog')
    elsif load_subsite.search_type == 'local'
      # ignore the offered filters for full-fledged subsites until either:
      # 1. there are multiple Solr cores
      # 2. there are collections published to non-catalog subsites
      url_for(action: 'index', controller: load_subsite.slug)
    else
      # initialize with facet values if present
      f = options.fetch('f', {}).merge(load_subsite.default_filters)
      if load_subsite.restricted.present?
        repository_id = @document[:lib_repo_code_ssim].first
        search_repository_catalog_path(repository_id: repository_id, f: f)
      else
        url_for(action: 'index', controller: 'catalog', f: f)
      end
    end
  end

  def browse_lists
    @browse_lists ||= begin
      if params[:action] == 'index'
        get_catalog_browse_lists
      else
        []
      end
    end
  end

  # TODO: the blacklight_configuration_context expects the controller to
  # have access to the condition evaluation methods; the BL 5 implementation
  # was in the helper context and thus has a controller accessor. The helpers
  # need to be refactored into a controller concern and just refer to self
  def controller
    self
  end
end
