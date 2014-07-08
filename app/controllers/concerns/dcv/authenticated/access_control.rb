module Dcv::Authenticated::AccessControl
  extend ActiveSupport::Concern

  included do
    if DCV_CONFIG['require_authentication']
      before_filter :require_authenticated_user!
    end
  end

  def require_authenticated_user!

    if ! user_signed_in?
      if (params[:controller] == 'devise/sessions') || (params[:controller] == 'users' && params[:action] == 'do_wind_login')
        # Allow access
      else
        redirect_to :controller => 'users', :action => 'do_wind_login'
      end
    end
  end

end
