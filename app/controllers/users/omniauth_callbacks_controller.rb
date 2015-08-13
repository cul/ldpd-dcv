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
  end
end