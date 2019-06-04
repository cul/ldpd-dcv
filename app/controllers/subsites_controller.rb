class SubsitesController < ApplicationController

  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Cul::Hydra::ApplicationIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility

  before_filter :set_view_path
  before_filter :store_unless_user, except: [:update, :destroy, :api_info]
  before_filter :authorize_action, only:[:index, :preview, :show]
  before_filter :default_search_mode_cookie, only: :index
  protect_from_forgery :except => [:update, :destroy, :api_info] # No CSRF token required for publishing actions

  helper_method :extract_map_data_from_document_list

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def initialize(*args)
    super(*args)
    self._prefixes << self.subsite_layout # haaaaaaack to not reproduce templates
    self._prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  def set_view_path
    self.prepend_view_path('app/views/catalog')
    self.prepend_view_path('app/views/' + self.subsite_layout)
    self.prepend_view_path(self.subsite_layout)
    self.prepend_view_path('app/views/' + controller_path)
    self.prepend_view_path(controller_path)
  end

  # Override to prepend restricted if necessary
  def authorize_action
    action_prefix = controller_path.split('/').join('_')
    action = "#{action_prefix}##{params[:action].to_s}"
    wildcard = "#{action_prefix}#*"
    current_user.role_symbols.concat session.fetch('cul.roles',[]).map(&:to_sym) if current_user
    current_user.role_symbols.uniq! if current_user
    proxy = Dcv::Authenticated::AccessControl::RoleAbilityProxy.new(document_id: params[:id],remote_ip: request.remote_ip, user_roles: session['cul.roles'])
    if can?(action.to_sym, proxy) || can?(wildcard.to_sym, proxy)
      return true
    else
      if current_user
        action = "#{action_prefix}#index"
        err_url = (can? action.to_sym, proxy) ?
          url_for(controller: controller_path, action: :index) : root_url
        access_denied(err_url)
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end

  def self.subsite_config
    subsite_config = {'nested' => SUBSITES[(self.restricted? ? 'restricted' : 'public')]}
    subsite_path = self.controller_path.split('/')
    subsite_path.shift if self.restricted?
    until subsite_path.empty?
      subsite_config = subsite_config.fetch('nested',{}).fetch(subsite_path.shift,{})
    end
    return subsite_config
  end

  def subsite_config
    return self.class.subsite_config
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
      IndexFedoraObjectJob.perform({'pid' => pid, 'subsite_keys' => [subsite_key]})
    rescue ActiveFedora::ObjectNotFoundError
      render status: :not_found, plain: ''
      return
    end
    response.headers['Location'] = published_url
    render status: status, json: { "success" => true }
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
    Blacklight.solr.delete_by_id(pid)
    Blacklight.solr.commit
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
    if self.controller_path.present? 
      self.controller_path.split('/').join('_')
    else
      self.class.restricted? ? "restricted_#{self.controller_name}" : self.controller_name
    end
  end

  def subsite_layout
    subsite_config['layout']
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
    render layout: 'minimal'
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
