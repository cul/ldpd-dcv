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
      render json: {
        user: user_json(current_user, ROLES[:admin], nil),
        }
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
      sites = []
      Site.all.each do |site|
        sites << site if editor_uids.include? uid
      end
      sites
    end

    # TODO: use camelCase -- right now not important bc we don't access first_name, etc. (any two-word attributes)
    def user_json(user, role, can_edit)
      {
        uid: user.uid,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        is_admin: user.is_admin,
        permissions: { role: role, can_edit: can_edit }
      }
    end
end