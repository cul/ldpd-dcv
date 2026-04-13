class Api::UsersController < Api::BaseController
  before_action :authenticate_user!

  ROLES = {
    admin: 'ADMIN',
    editor: 'EDITOR',
    user: 'USER'
  }.freeze

  # GET /api/v1/users/_self
  def _self
    if current_user.is_admin
      render json: { user: user_json(current_user, ROLES[:admin], nil) }
        return
    end
    sites = list_can_edit_sites(current_user.uid)
    role = sites.any? ? ROLES[:editor] : ROLES[:user]

    render json: {
      user: user_json(current_user, role, sites.map(&:slug)),
    }
  end

  private

    def list_can_edit_sites(uid)
      # I couldn't figure out a better way to do this in an sqlite where clause, because sqlite has no 'ANY' operator
      Site.all.select { |site| site[:editor_uids].include? uid }
    end

    def user_json(user, role, can_edit)
      {
        uid: user.uid,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        permissions: { role: role, canEdit: can_edit }
      }
    end
end