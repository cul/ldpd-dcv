class Api::UsersController < Api::BaseController
  before_action :authenticate_user!

  # GET /api/v1/users/_self
  def _self
    render json: { user: user_json(current_user) }
  end

  private
    def user_json(user)
      {
        uid: user.uid,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        is_admin: user.is_admin,
      }
    end
end