class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks
  skip_before_action :verify_authenticity_token #, :only => [:create,:update]
  def developer
    uid = request.env['omniauth.auth'][:info][:uni]
    email = request.env['omniauth.auth'][:info][:email]
    current_user ||= User.find_or_create_by!(
      uid: uid, email: email, provider: :developer
    )

    sign_in_and_redirect current_user, event: :authentication
  end

  def affils(user, affils)
    affiliations(user, affils)
  end

  def affiliations(user, affils)
    return unless user && user.uid
    session['cul.roles'] = affils.select { |affil| affil =~ /^(CUL|LIB|CNET)/ }
  end

  def after_sign_out_path_for(resource_name)
    session['logout_redirect_url'] || super
  end

end