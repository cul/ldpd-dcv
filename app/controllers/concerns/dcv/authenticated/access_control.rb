module Dcv::Authenticated::AccessControl
  extend ActiveSupport::Concern

  included do
    if DCV_CONFIG.blank? || DCV_CONFIG['require_authentication'].nil? || DCV_CONFIG['require_authentication']
      before_action :require_user, except: [:index_object]
    end
  end

  def redirect_to_login
    redirect_to send(:"user_#{omniauth_provider_key}_omniauth_authorize_path", url: session[:return_to])
  end

  def omniauth_provider_key
    @omniauth_provider_key ||= Rails.application.cas_configuration_opts[:provider]
  end

  def authorize_action_and_scope(action, scope)
    raise CanCan::AccessDenied unless can?(action, scope)
  end

  def authorize_document(_document=nil)
    authorize_action_and_scope(Ability::ACCESS_SUBSITE, self)
  end

  def authorize_site_update(site=@subsite)
    authorize_action_and_scope(:update, site)
  end
end
