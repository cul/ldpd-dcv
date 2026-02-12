class AdminController < ApplicationController
  layout 'admin'
  before_action :ensure_authenticated, only: [:index]

  # Entrypoint for react UI app
  def index
  end

  private

  def ensure_authenticated
    raise CanCan::AccessDenied unless user_signed_in?
  end
end
