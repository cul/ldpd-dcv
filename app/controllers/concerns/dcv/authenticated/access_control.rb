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

  def authz_proxy_for(document,opts={})
    opts[:content_models] = document[:has_model_ssim].collect {|rel| rel.to_s}
    opts[:publisher] = document[:publisher_ssim].collect {|rel| rel.to_s}
    Cul::Omniauth::AbilityProxy.new(opts)
  end

  def authorize_document(document=@document, action=:'documents#show')
    proxy = authz_proxy_for(document)
    if can? action, proxy
      return true
    else
      if current_user
        access_denied
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end
end
