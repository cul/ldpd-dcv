class SubsitesController < ApplicationController

  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::MarkdownRendering
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Sites::SearchableController
  include Cul::Hydra::ApplicationIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include ShowFieldDisplayFieldHelper

  before_action :store_unless_user, except: [:update, :destroy, :api_info]
  before_action :authorize_action, only:[:index, :preview, :show]
  before_action :default_search_mode_cookie, only: :index
  before_action :load_subsite, except: [:home, :page]
  before_action :load_page, only: [:home, :index, :page]
  protect_from_forgery :except => [:update, :destroy, :api_info] # No CSRF token required for publishing actions


  helper_method :extract_map_data_from_document_list

  layout Proc.new { |controller|
    self.subsite_layout
  }

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
    self._prefixes.unshift(controller_path.sub('restricted/', '')) if self.restricted?
    self._prefixes.unshift ""
  end

  # overrides the session role key from Cul::Omniauth::RemoteIpAbility
  def current_ability
    @current_ability ||= Ability.new(current_user, roles: session["cul.roles"], remote_ip:request.remote_ip)
  end

  # view paths look up partial templates within _prefixes
  # paths are relative to Rails.root
  # prepending because we want to give specialized path priority
  def set_view_path
    self.prepend_view_path('app/views/shared')
    self.prepend_view_path('app/views/' + self.subsite_layout)
    self.prepend_view_path('app/views/' + controller_path.sub('restricted/', '')) if self.restricted?
    self.prepend_view_path('app/views/' + controller_path)
  end

  def authorize_action
    raise CanCan::AccessDenied unless can?(Ability::ACCESS_SUBSITE, self)
  end

  def self.subsite_config
    @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(controller_path, self.restricted?)
  end

  def subsite_config
    @subsite_config ||=  self.class.subsite_config
  end

  def self.load_subsite
    @subsite ||= Site.find_by(slug: controller_path)
  end

  def load_subsite
    @subsite ||= self.class.load_subsite
  end

  def load_page
    if params[:slug]
      @page = load_subsite.site_pages.find_by(slug: params[:slug])
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
    publishers = Array(subsite_config.dig('scope_constraints','publisher')).compact
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
    # Do not include the publish target itself or any additional publish targets defined in search results
    if exclude_by_id
      config.default_solr_params[:fq] << '-id:("' + publishers.map{|info_fedora_prefixed_pid| info_fedora_prefixed_pid.gsub('info:fedora/', '') }.join('" OR "') + '")'
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
      render status: :not_found, plain: ''
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
      params[:id] = @document.id
    else
      @response, @document = fetch params[:id]
    end
  end

  # GET /subsite/:id
  def show
    params[:format] ||= 'html'
    setup_show_document
    authorize_document

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
      render status: :bad_request, message: 'document_id param is required', nothing: true
    end
    document_id ||= params[:document_id].dup
    document_id.gsub!(/\:/,'\:')
    sp = blacklight_config.default_document_solr_params.merge({})
    sp[:fq] = "identifier_ssim:#{document_id}"
    solr_response, docs = search_results({}) { |b| b.merge(sp) }
    if docs.empty?
      render status: :not_found, message: "no document with id #{params[:document_id]}", nothing: true
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
    get_asset_url(id: document['id'], size: 256, format: 'jpg', type: 'featured')
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
end
