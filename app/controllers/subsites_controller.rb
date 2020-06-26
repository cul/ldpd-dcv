class SubsitesController < ApplicationController

  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::MarkdownRendering
  include Cul::Hydra::ApplicationIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include ShowFieldDisplayFieldHelper

  before_filter :store_unless_user, except: [:update, :destroy, :api_info]
  before_filter :authorize_action, only:[:index, :preview, :show]
  before_filter :default_search_mode_cookie, only: :index
  before_filter :load_subsite, except: [:home, :index, :page]
  before_filter :load_page, only: [:home, :index, :page]
  protect_from_forgery :except => [:update, :destroy, :api_info] # No CSRF token required for publishing actions


  helper_method :extract_map_data_from_document_list

  layout Proc.new { |controller|
    self.subsite_layout
  }

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
    self._prefixes.unshift self.subsite_layout
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
    self.prepend_view_path('app/views/catalog')
    self.prepend_view_path('app/views/' + controller_path)
    self.prepend_view_path('app/views/' + self.subsite_layout)
  end

  # Override to prepend restricted if necessary
  def authorize_action
    if can?(Ability::ACCESS_SUBSITE, self)
      return true
    else
      if current_user
        access_denied(catalog_index_url)
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end

  def self.subsite_config
    SubsiteConfig.for_path(controller_path, self.restricted?)
  end

  def subsite_config
    return self.class.subsite_config
  end

  def load_subsite(*pages)
    @subsite ||= begin
      site_slug = controller_path
      if pages.blank?
        Site.includes(:nav_links, :site_pages).find_by(slug: site_slug)
      else
        Site.includes(:nav_links, site_pages: [:site_text_blocks]).find_by(slug: site_slug, site_pages: { slug: pages })
      end
    end
  end

  def load_page
    if params[:slug]
      @page = load_subsite(params[:slug]).site_pages.where(slug: params[:slug]).first
    else
      unless has_search_parameters?
        @page ||= load_subsite('home').site_pages.includes(:site_text_blocks).find_by(slug: 'home')
      end
    end
  end

  def default_search_mode
    subsite_config.fetch('default_search_mode',:grid)
  end

  def default_search_mode_cookie
    cookie_name = "#{subsite_layout}_search_mode".to_sym
    cookie = cookies[cookie_name]
    unless cookie
      cookies[cookie_name] = default_search_mode.to_sym
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
      IndexFedoraObjectJob.perform({'pid' => pid, 'subsite_keys' => [subsite_key], 'reraise' => true})
      response.headers['Location'] = published_url
      render status: status, json: { "success" => true }
    rescue ActiveFedora::ObjectNotFoundError
      render status: :not_found, plain: ''
      return
    rescue
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

  # GET /subsite/:id
  def show
    params[:format] = 'html'

    @response, @document = fetch params[:id]
    return unless authorize_document

    respond_to do |format|
      format.html do
        setup_next_and_previous_documents
        render 'show' # explicate since proxies action delegates here
      end

      format.json { render json: {response: {document: @document}}}

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
      end
    end
  end

  def preview
    @response, @document = fetch(params[:id], fl:'*')
    return unless authorize_document

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

  def subsite_key
    if self.controller_path.present? 
      self.controller_path.split('/').join('_')
    else
      self.class.restricted? ? "restricted_#{self.controller_name}" : self.controller_name
    end
  end

  def subsite_layout
    load_subsite&.layout || subsite_config['layout']
  end

  def subsite_styles
    palette = @subsite&.palette || subsite_config['palette']
    palette.present? ? "#{subsite_layout}-#{palette}" : subsite_layout
  end

  def search_result_view_overrides
    subsite_config['search_result_view_overrides'] || {}
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
    return unless authorize_document
    render layout: 'minimal', locals: { document: @document }
  end

  private

  def extract_map_data_from_document_list(document_list)

    # We want this data to be as compact as possible because we're sending a lot to the client

    max_title_length = 50

    map_data = []
    document_list.each do |document|
      if document['geo'].present?
        document['geo'].each do |coordinates|

          lat_and_long = coordinates.split(',')

          is_book = document['lib_format_ssm'].present? && document['lib_format_ssm'].include?('books')

          title = document['title_display_ssm'][0].gsub(/\s+/, ' ') # Compress multiple spaces and new lines into one
          title = title[0,max_title_length].strip + '...' if title.length > max_title_length

          row = {
            id: document.id,
            c: lat_and_long[0].strip + ',' + lat_and_long[1].strip,
            t: title,
            b: is_book ? 'y' : 'n',
          }

          map_data << row
        end
      end
    end

    return map_data
  end

end
