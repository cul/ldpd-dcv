class ApplicationController < ActionController::Base

  include Dcv::Authenticated::AccessControl

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  before_filter :set_view_path

  layout false

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def initialize(*args)
    super(*args)
    self._prefixes << 'catalog' # haaaaaaack to not reproduce templates
    self._prefixes << 'shared' # haaaaaaack to not reproduce templates
  end

  # this is overridden in SubsitesController
  def set_view_path
    self.prepend_view_path('app/views/shared')
    self.prepend_view_path('app/views/catalog')
    self.prepend_view_path('app/views/dcv')
    self.prepend_view_path('dcv')
    self.prepend_view_path('app/views/' + controller_path)
    self.prepend_view_path(controller_path)
  end

  def render_unauthorized!
    render 'pages/unauthorized', :status => :unauthorized
  end

  def store_unless_user
    store_location unless current_user
  end
end
