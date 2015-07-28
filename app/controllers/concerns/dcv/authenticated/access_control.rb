module Dcv::Authenticated::AccessControl
  extend ActiveSupport::Concern

  included do
    if DCV_CONFIG.blank? || DCV_CONFIG['require_authentication'].nil? || DCV_CONFIG['require_authentication']
      before_filter :require_user, except: [:index_object]
    end
  end

  def redirect_to_login
    redirect_to user_omniauth_authorize_path(provider: omniauth_provider_key, url:session[:return_to])
  end

  def omniauth_provider_key
    @omniauth_provider_key ||= Dcv::Application.cas_configuration_opts[:provider]
  end

end
