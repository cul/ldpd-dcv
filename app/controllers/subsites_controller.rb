class SubsitesController < ApplicationController

  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::MarkdownRendering
  include Dcv::MapDataController
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Sites::SearchableController
  include Dcv::Sites::ApplicationIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include ShowFieldDisplayFieldHelper

  before_action :store_unless_user, except: [:update, :destroy, :api_info]
  before_action :authorize_action, only:[:index, :preview, :show]
  before_action :default_search_mode_cookie, only: :index
  before_action :load_subsite, except: [:home, :page]
  before_action :load_page, only: [:home, :index, :page]
  before_action :meta_nofollow!, only: [:index, :map_search]
  before_action :meta_noindex!, only: [:index, :map_search]
  protect_from_forgery :except => [:update, :destroy, :api_info] # No CSRF token required for publishing actions

  helper_method :extract_map_data_from_document_list

  layout Proc.new { |controller|
    self.subsite_layout
  }

  rescue_from ActiveRecord::RecordNotFound, with: :on_page_not_found

  self.search_state_class = Dcv::SearchState
  # TODO: the blacklight_configuration_context expects the controller to
  # have access to the condition evaluation methods; the BL 5 implementation
  # was in the helper context and thus has a controller accessor. The helpers
  # need to be refactored into a controller concern and just refer to self
  def controller
    self
  end

  def initialize(*args)
    super(*args)
    # _prefixes are where view path lookups are attempted; probably unnecessary
    # but need testing. default blank value should be first, but layout needs to be in front of controller path
    self._prefixes.unshift "shared"
    self._prefixes.unshift self.subsite_layout
    self._prefixes.unshift(self.restricted? ? controller_path.sub('restricted/', '') : controller_path) 
    self._prefixes.unshift ""
  end

  def set_view_path
    prepend_view_path('app/views/' + subsite_layout)

    custom_layout = self.restricted? ? controller_path.sub('restricted/', '') : controller_path
    prepend_view_path('app/views/' + custom_layout)
    prepend_view_path(custom_layout)
  end

  # overrides the session role key from Cul::Omniauth::RemoteIpAbility
  def current_ability
    @current_ability ||= Ability.new(current_user, roles: session["cul.roles"], remote_ip:request.remote_ip)
  end

  def authorize_action
    raise CanCan::AccessDenied unless can?(Ability::ACCESS_SUBSITE, self)
  end

  def self.subsite_config
    @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(controller_path, self.restricted?)
  end

  def subsite_config
    @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(self.class.controller_path, self.restricted?)
  end

  def self.load_subsite
    Site.find_by(slug: controller_path)
  end

  def load_subsite
    @subsite ||= Site.find_by(slug: self.class.controller_path)
  end

  def load_page
    if params[:slug]
      @page ||= load_subsite.site_pages.find_by(slug: params[:slug])
    else
      unless has_search_parameters?
        @page ||= load_subsite.site_pages.find_by(slug: 'home')
      end
    end
  end

  # some custom sites have local styles even when using a non-custom layout
  def subsite_styles
    (super + [controller_name]).uniq
  end

  def self.configure_blacklight_scope_constraints(config, exclude_by_id = false)
    if load_subsite
      publishers = load_subsite.default_filters.fetch('publisher_ssim', [])
      config.default_solr_params[:fq] += load_subsite.default_fq
    else
      publishers = Array(subsite_config.dig('scope_constraints','publisher')).compact
      config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
    end
    # Do not include the publish target itself or any additional publish targets defined in search results
    if exclude_by_id
      config.default_solr_params[:fq] << '-id:("' + publishers.map{|info_fedora_prefixed_pid| info_fedora_prefixed_pid.gsub('info:fedora/', '') }.join('" OR "') + '")'
    end
  end

  def render_home_for_index?
    !has_search_parameters? && request.format.html?
  end

  def index
    super
    if render_home_for_index?
      # we override the view rendered for the subsite home on html requests
      params[:action] = 'home'
      render 'home'
    end
  end

  # PUT /subsite/publish/:id
  def update
    pid = params[:id]
    unless (status = authenticate_publisher) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    published_url = url_for(controller: controller_name, action: :show, id: pid)
    logger.debug "reindexing #{pid}"
    begin
      solr_doc = IndexFedoraObjectJob.perform({'pid' => pid, 'subsite_keys' => [subsite_key], 'reraise' => true})
      if solr_doc&.doi_identifier
        registrant, doi = solr_doc.doi_identifier.split('/')
        published_url = resolve_doi_url(registrant: registrant, doi: doi)
      end
      response.headers['Location'] = published_url
      render status: status, json: { "success" => true }
    rescue ActiveFedora::ObjectNotFoundError
      render status: :not_found, plain: "object not found"
      return
    rescue StandardError => e
      Rails.logger.error("#{e.message}\n\t#{e.backtrace.join("\n\t")}")
      # despite json body, Hyacinth 2 relies on status code to determine success/failure
      render status: :internal_server_error, json: { "success" => false }
    end
  end

  # DELETE /subsite/publish/:id
  def destroy
    pid = params[:id]
    unless (status = authenticate_publisher) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    # TODO: If we eventually have different solr indexes for
    # different subsites, make sure to use the correct solr
    # url for each subsite. For now, it's safe to use our
    # one and only Blacklight.solr url.
    Blacklight.default_index.connection.delete_by_id(pid)
    Blacklight.default_index.connection.commit
    render json: {
      "success" => true
    }
  end

  # GET /subsite/publish
  def api_info
    render json: {
      "api_version" => "1.0.0"
    }
  end

  def setup_show_document
    if params[:id] =~ Dcv::Routes::DOI_ID_CONSTRAINT[:id]
      @response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=ezid_doi_ssim v=$#{blacklight_config.document_unique_id_param}}"
      params[:id] = @document&.id
    else
      @response, @document = fetch params[:id]
    end
  end

  def home
  end

  # GET /subsite/:id
  def show
    params[:format] ||= 'html'
    setup_show_document
    authorize_document

    unless @document
      render file: 'public/404.html', layout: false, status: 404
      return
    end

    respond_to do |format|
      format.html do
        @search_context = setup_next_and_previous_documents || {}
        render 'show' # explicate since proxies action delegates here
      end

      format.json { render json: {response: {document: @document}}}

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        format.send(format_name.to_sym) { render plain: @document.export_as(format_name), layout: false }
      end
    end
  end

  def preview
    @response, @document = fetch(params[:id], fl:'*')
    authorize_document

    render layout: 'preview', locals: { document: @document }
  end

  def proxies
    show
  end

  def legacy_redirect
    unless params[:document_id]
      render status: :bad_request, plain: 'document_id param is required'
    end
    document_id ||= params[:document_id].dup
    document_id.gsub!(/\:/,'\:')
    sp = blacklight_config.default_document_solr_params.merge({})
    sp[:fq] = "identifier_ssim:#{document_id}"
    solr_response, docs = search_results({}) { |b| b.merge(sp) }
    if docs.empty?
      render status: :not_found, plain: "no document with id #{params[:document_id]}"
      return
    end
    document = docs.first
    redirect_to action: "show", id: document[:id]
  end

  # subsite_key is used for:
  #  scoping cookies, index jobs, and map cache
  #  layout configuration
  # custom sites that are restricted scope all of these things without prefix
  # non-restricted exceptions that need to be captured:
  #   carnegie/centennial
  #   nyre/projects (locally overridden)
  def subsite_key
    if self.class.restricted?
      self.controller_name
    else
      self.controller_path.split('/').join('_')
    end
  end

  def thumb_url(document={})
    get_asset_url(id: document['id'], size: 256, format: 'jpg', base_type: 'featured', type: 'full')
  end

  def authenticate_publisher
    status = :unauthorized
    authenticate_with_http_token do |token, other_options|
      (subsite_config || {}).tap do |config|
        status = (config['remote_request_api_key'] == token) ? :ok : :forbidden
      end
    end
    status
  end

  def page
    raise ActiveRecord::RecordNotFound unless @page
  end

  def synchronizer
    @response, @document = fetch(params[:id], fl:'*')
    authorize_document
    render layout: 'minimal', locals: { document: @document }
  end

  # TODO: Implement featured_items for full subsites
  # produce a lazily-loaded list of featured items according to a supplied filter
  def featured_items(args= {})
    []
  end

  # use existing response attribute
  def load_facet_response
    @response
  end

  def tracking_method
    self.restricted? ? "track_restricted_#{controller_name}_path" : "track_#{controller_name}_path"
  end

  def search_action_url(params = {})
    url_for(params.merge(controller: controller_name, action: :index))
  end
end
