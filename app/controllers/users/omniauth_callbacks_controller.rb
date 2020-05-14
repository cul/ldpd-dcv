class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks
  skip_before_filter :verify_authenticity_token #, :only => [:create,:update]
  def developer
    current_user ||= User.find_or_create_by(email:request.env["omniauth.auth"][:uid])
    #current_user.staff = true
    
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