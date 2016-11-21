class SubsitesController < ApplicationController

  include Dcv::CatalogIncludes
  include Cul::Hydra::ApplicationIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility

  before_filter :set_view_path
  before_filter :store_unless_user, except: [:update, :destroy, :api_info]
  before_filter :authorize_action, only:[:index, :preview, :show]
  protect_from_forgery :except => [:index_object] # No CSRF token required for reindex

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def initialize(*args)
    super(*args)
    self._prefixes << self.subsite_layout # haaaaaaack to not reproduce templates
    self._prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  def set_view_path
    self.prepend_view_path(self.subsite_layout)
  end

  def restricted?
    self.class.restricted?
  end

  # Override to prepend restricted if necessary
  def authorize_action
    if self.class.restricted?
      action = "restricted_#{controller_name.to_s}##{params[:action].to_s}"
      wildcard = "restricted_#{controller_name.to_s}#*"
    else
      action = "#{controller_name.to_s}##{params[:action].to_s}"
      wildcard = "#{controller_name.to_s}#*"
    end
    proxy = Cul::Omniauth::AbilityProxy.new(document_id: params[:id],remote_ip: request.remote_ip)
    if can?(action.to_sym, proxy) || can?(wildcard.to_sym, proxy)
      return true
    else
      if current_user
        action = "#{controller_name.to_s}#index"
        action = 'restricted_' + action if self.class.restricted?
        err_url = (can? action.to_sym, proxy) ?
          url_for(controller: controller_name, action: :index) : root_url
        access_denied(err_url)
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end

  def subsite_config
    return SUBSITES[(self.class.restricted? ? 'restricted' : 'public')].fetch(self.controller_name,{})
  end

  def default_search_mode
    subsite_config.fetch('default_search_mode',:grid)
  end

  def self.restricted?
    return controller_path.start_with?('restricted/')
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
      IndexFedoraObjectJob.perform({'pid' => pid, 'subsite_keys' => [subsite_key]})
    rescue ActiveFedora::ObjectNotFoundError
      render status: :not_found, plain: ''
      return
    end
    response.headers['Location'] = published_url
    render json: {
      "success" => true
    }
  end

  # DELETE /subsite/publish/:id
  def destroy
    pid = params[:id]
    unless (status = authenticate_publisher) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    rsolr.delete_by_id(pid)
    rsolr.commit
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

    @response, @document = get_solr_response_for_doc_id   
    return unless authorize_document

    respond_to do |format|
      format.html {setup_next_and_previous_documents}

      format.json { render json: {response: {document: @document}}}

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
      end

    end
  end

  def preview
    @response, @document = get_solr_response_for_doc_id(params[:id], fl:'*')
    return unless authorize_document

    render layout: 'preview'
  end

  def subsite_key
    return (self.class.restricted? ? 'restricted_' : '') + self.controller_name
  end

  def subsite_layout
    SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]['layout']
  end

  def thumb_url(document={})
    get_asset_url(id: document['id'], size: 256, format: 'jpg', type: 'featured')
  end

  def authenticate_publisher
    status = :unauthorized
    authenticate_with_http_basic do |user, pass|
      (subsite_config || {}).tap do |config|
        status = (config['remote_request_api_user'] == user && config['remote_request_api_key'] == pass) ? :ok : :forbidden
      end
    end
    status
  end

end
