require 'redcarpet'

class SitesController < ApplicationController
  include Dcv::DigitalProjectsController
  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::CdnHelper
  include Dcv::MarkdownRendering
  include Dcv::DcvUrlHelper # access to url_for_document
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Sites::SearchableController
  include Cul::Omniauth::AuthorizingController
  include ShowFieldDisplayFieldHelper

  before_action :browse_lists, only: :index
  before_action :load_subsite, except: [:index]
  before_action :load_page, only: [:home]
  before_action :authorize_site_update, only: [:edit, :update]

  layout :request_layout

  self.search_state_class = Dcv::Sites::SearchState

  # these need to be removed from the processor chain when not searching for site records
  SITES_PROCESSOR_CHAIN = [:constrain_to_slug, :constrain_to_public_sites, :constrain_to_restricted_sites]


  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config)
    config.default_solr_params = {
      :fq => [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:Concept',
        'dc_type_sim:"Publish Target"',
        '-slug_ssim:sites', # Do not include sites publish targets in this list
      ],
      :sort => "title_si asc, lib_date_dtsi desc",
      :qt => 'search'
    }

    config.default_per_page = 250
    config.per_page = [20,60,100,250]
    config.max_per_page = 250
    config.track_search_session = false # don't track blank or featured searches on home pages

    # solr field configuration for search results/index views
    config.index.title_field = 'title_display_ssm'
    config.index.display_type_field = 'active_fedora_model_ssi'
    config.index.thumbnail_method = :thumbnail_for_doc
    config.add_index_field 'abstract_ssim', :label => 'Abstract'
    config.add_index_field 'schema_image_ssim', :label => 'Representative Image'
    config.add_index_field 'short_title_ssim', :label => 'Facet Value'
    config.add_index_field 'slug_ssim', :label => 'Slug'
    config.add_index_field 'source_ssim', :label => 'Site URL'
    config.add_index_field 'title_ssim', :label => 'Title'

    config.show.title_field = 'title_display_ssm'
    config.add_show_field 'description_ssm', :label => 'Description'
    config.add_show_field 'schema_image_ssim', :label => 'Representative Image'
    config.add_show_field 'short_title_ssim', :label => 'Facet Value'
    config.add_show_field 'slug_ssim', :label => 'Slug'
    config.add_show_field 'source_ssim', :label => 'Site URL'
    config.add_show_field 'title_ssim', :label => 'Title'
    config.add_sort_field 'title_si asc', :label => 'title'

    # All Text search configuration, used by main search pulldown.
    config.add_search_field 'all_text_teim' do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => ['all_text_teim'],
        :pf => ['all_text_teim']
      }
    end
  end


  def search_service_context
    { builder: { addl_processor_chain: [:constrain_to_slug, self.restricted? ? :constrain_to_restricted_sites : :constrain_to_public_sites] } }
  end

  def index
    respond_to do |format|
      format.json {
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET'
        (@response, @document_list) = search_service.search_results
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

  prepend_view_path('app/views/sites')

  def set_view_path
    self.prepend_view_path('app/views/' + self.request_layout)
    self.prepend_view_path('app/views/' + load_subsite.slug.sub('%2F', '/')) unless params[:action] == 'index'
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
      s = Site.find_by(slug: site_slug)
      s.configure_blacklight! if s
      s
    end
  end

  def load_page
    @page ||= load_subsite.site_pages.find_by(slug: 'home')
  end

  def request_layout
    if (action_name == 'index')
      'gallery' # legacy behavior
    elsif (action_name == 'edit')
      'sites'
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

  # get single document from the solr index
  # override to use :slug and publisher_ssim in search to get document
  def home
    if load_subsite.nil?
      render status: :not_found, text: "#{params[:slug]} is not a subsite"
      return
    end
    load_site_document
    # override the blacklight config to support featured content and facets
    @blacklight_config = load_subsite.blacklight_config
    # TODO: load facet data. Requires configuration of fields, and override of default solr params.
    respond_to do |format|
      format.json { render json: @subsite.to_json }
      format.html { render }
    end
  end

  # authorize edit access and display form for editing static content
  def edit
  end

  # update sanitized params
  def update
    site_attributes = site_params
    # though Site accepts nested attributes of nav_links for persistence, we want to handle the updates
    # specially (to accommodate the deletion and reordering without recourse to record id)
    nav_links_attributes = site_attributes.delete('nav_links_attributes')
    banner_upload = params[:site].delete(:banner)
    watermark_upload = params[:site].delete(:watermark)
    begin
      @subsite.update! site_attributes
      if nav_links_attributes.present?
        @subsite.nav_links.each do |nav_link|
          if nav_links_attributes.present?
            # update this available link record
            nav_link.update! nav_links_attributes.shift
          else
            # out of attributes so delete remaining nav links
            nav_link.destroy
          end
        end
        # remaining attributes represent new nav links that must be added
        nav_links_attributes.each do |nav_link_attributes|
          @subsite.nav_links.create!(nav_link_attributes)
        end
      else
        @subsite.nav_links.destroy_all
      end
      if banner_upload
        BannerUploader.new(@subsite).store!(banner_upload) && @subsite.touch
      end
      if watermark_upload
        WatermarkUploader.new(@subsite).store!(watermark_upload) && @subsite.touch
      end
      flash[:notice] = "Saved!"
    rescue ActiveRecord::RecordInvalid => ex
      flash[:alert] = ex.message
    rescue CarrierWave::IntegrityError => ex
      flash[:alert] = ex.message
    end
    if restricted?
      redirect_to edit_restricted_site_path(slug: @subsite.slug.sub('restricted/', ''))
    else
      redirect_to edit_site_path(slug: @subsite.slug)
    end
  end

  # produce a list of featured items according to a supplied filter
  def featured_items(args= {})
    (@response, @document_list) = search_service.search_results do |builder|
      addl_params = site_search_params
      merge_params = {rows: args.fetch(:rows, 12), sort: addl_params.delete(:sort)}.compact
      builder.except(*SITES_PROCESSOR_CHAIN).append(:filter_random_suppressed_content).with(addl_params).merge(merge_params)
    end
    @document_list
  end

  # load facet response
  def load_facet_response
    @response ||= begin
      results = search_results(params) do |builder|
        builder.except(*SITES_PROCESSOR_CHAIN).merge(rows: 0)
      end
      results[0] # do not store list as attribute
    end
    @response
  end

  # solr params for site content
  def site_search_params(args = {})
      result = load_subsite.blacklight_config.default_solr_params.merge(sort: "random_#{Random.new_seed} DESC")
      result.merge(args)
  end

  def published_to_catalog?(document={})
    document && document.fetch('publisher_ssim',[]).include?(catalog_uri)
  end

  def catalog_uri
    SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
  end

  def search_url_service
    @search_url_service ||= Dcv::Sites::SearchUrlService.new
  end

  # this is only used from site home pages or the sites listing
  def search_controller_params(options = {})
    if action_name == 'index'
      options.merge(controller: '/catalog')
    else
      search_url_service.search_controller_params(load_subsite, options)
    end
  end
  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  # see also HomeController
  def search_action_url(options = {})
    if action_name == 'index'
      url_for(search_controller_params(options.merge(action: 'index')))
    else
      search_url_service.search_action_url(load_subsite, self, options)
    end
  end

  # Override from core BL to remove slug
  def search_facet_path(options = {})
    opts = search_state
           .to_h
           .merge(action: "facet", only_path: true)
           .merge(search_controller_params(options))
           .except(:page, :slug)
    url_for opts
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

  def tracking_method
    "#{controller_name}_track_path"
  end

  def load_site_document
    @document ||= SitesController.site_as_solr_document(load_subsite)
  end

  def self.site_as_solr_document(site)
    Dcv::Sites::Export::Solr.new(site).run
  end

  private
    def unroll_nav_link_params
      nav_menus_attributes = params['site'].delete('nav_menus_attributes')
      return unless nav_menus_attributes
      nav_links = []
      nav_menus_attributes.each do |group_index, group_data|
        sort_group = "#{sprintf("%02d", group_index.to_i)}:#{group_data['label']}"
        group_data.fetch('links_attributes', {}).each do |link_index, link_data|
          sort_label = "#{sprintf("%02d", link_index.to_i)}:#{link_data['label']}"
          nav_links << {sort_group: sort_group, sort_label: sort_label, link: link_data['link'], external: link_data['external']}
        end
      end
      params['site']['nav_links_attributes'] = nav_links
    end

    def site_params
      unroll_nav_link_params
      params.require(:site).permit(:palette, :layout, :show_facets, :alternative_title, :search_type, :editor_uids, :image_uris, :nav_links_attributes,
                                   image_uris: [], nav_links_attributes: [:sort_group, :sort_label, :link, :external])
      .to_h.tap do |p|
        p.delete('banner')
        p.delete('watermark')
        p['image_uris']&.delete_if { |v| v.blank? }
      end
    end
end
