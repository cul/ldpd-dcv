class ApplicationController < ActionController::Base

  include Dcv::Authenticated::AccessControl
  include Dcv::CrossOriginRequests

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  before_action :set_view_path

  layout false

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::Live::ClientDisconnected, with: :on_client_disconnect

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      store_location
      redirect_to_login
    else
      access_denied
    end
  end

  self.search_service_class = Dcv::SearchService

  # Cache view path resolvers to address a memory leak fixed in Rails 7.1.3
  # see also https://github.com/rails/rails/pull/47347
  def self.cached_view_resolver(view_path)
    @cached_resolvers ||= Concurrent::Map.new
    @cached_resolvers.fetch_or_store(view_path) do
      ActionView::Resolver === view_path ? view_path : ActionView::OptimizedFileSystemResolver.new(view_path)
    end
  end

  # Override prepend_view_path to address a memory leak fixed in Rails 7.1.3
  # see also https://github.com/rails/rails/pull/47347
  def prepend_view_path(view_paths)
    Array(view_paths).each do |view_path|
      resolver = ApplicationController.cached_view_resolver(view_path)

      # clear the resolver's cache if the application environment is not caching templates
      # https://github.com/rails/rails/issues/14301#issuecomment-771651933
      resolver.clear_cache unless ActionView::Resolver.caching?
      super(resolver)
    end
  end

  def initialize(*args)
    super(*args)
    self._prefixes << 'catalog' # haaaaaaack to not reproduce templates
    self._prefixes << 'shared' # haaaaaaack to not reproduce templates
  end

  append_view_path('app/views/shared')

  # this is overridden in SubsitesController and SitesController
  def set_view_path
    prepend_view_path('app/views/' + controller_path)
    prepend_view_path(controller_path)
  end

  def render_unauthorized!
    render 'pages/unauthorized', :status => :unauthorized
  end

  def store_unless_user
    store_location unless current_user
  end

  # Overridden in relevant subclasses
  def reading_room_client?
    false
  end

  def show_file_fields?(field_config, document)
    document.resource_result?
  end

  def external_service_client_ip
    DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
  end

  # this is overridden in most controllers
  def load_subsite
    nil
  end

  def on_client_disconnect
    Rails.logger.info("Client disconnected (##{Process.pid})")
  end

  def on_page_not_found
    render(status: :not_found, plain: "Page Not Found")
  end
end
