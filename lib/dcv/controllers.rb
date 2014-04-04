module Dcv::Controllers
  module Authenticated
    def self.included(controller)
      controller.before_filter :require_authenticated_user!
    end

    # Permission/Authorization methods
    def require_authenticated_user!
      if ! user_signed_in?

        if (params[:controller] == 'pages' && params[:action] == 'home') ||
          (params[:controller] == 'devise/sessions') ||
          (params[:controller] == 'users' && params[:action] == 'do_wind_login') ||
          (params[:controller] == 'pages' && params[:action] == 'login_check') ||
          (params[:controller] == 'pages' && params[:action] == 'get_csrf_token')
         # Allow access
        else
          redirect_to root_path
        end
      end
    end

    def require_admin!
      unless current_user.is_admin?
        render_unauthorized!
      end
    end

    def require_project_permission!(project, permission_type)

      # Always allow access if this user is an admin
      return if current_user.is_admin?

      return if current_user.has_project_permission?(project, permission_type)

      render_unauthorized!
    end
  end
end
