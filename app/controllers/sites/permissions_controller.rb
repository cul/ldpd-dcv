module Sites
	class PermissionsController < ApplicationController
		include Dcv::RestrictableController
		include Cul::Omniauth::AuthorizingController
		before_action :load_subsite
		before_action :authorize_site_update
		layout 'sites'

		def load_subsite
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				Site.find_by(slug: site_slug)
			end
		end

		def update
			begin
				update_attributes = permissions_params
				update_attributes[:permissions]&.tap {|atts| @subsite.permissions.assign_attributes(atts) }
				update_attributes[:editor_uids]&.tap {|atts| @subsite.editor_uids = atts }
				@subsite.save! if @subsite.changed?
				flash[:notice] = "Saved!"
			rescue ActiveRecord::RecordInvalid => ex
				flash[:alert] = ex.message
			end
			@subsite.save! if @subsite.changed?
			if restricted?
				redirect_to edit_restricted_site_permissions_path(site_slug: @subsite.slug.sub('restricted/', ''))
			else
				redirect_to edit_site_permissions_path(site_slug: @subsite.slug)
			end
		end

		def show
			redirect_to action: :edit
		end

		def edit
		end

		def permissions_params
			params['site']&.tap do |atts|
				if can?(:admin, @subsite)
					atts['editor_uids']&.strip!
					atts['editor_uids'] = atts['editor_uids'].split(/[\s,]+/).sort
				else
					atts['editor_uids'] = @subsite.editor_uids
				end
			end
			params.dig('site', 'permissions')&.tap do |atts|
				atts['remote_ids'] = atts['remote_ids'].split(/[\s,]+/).sort if atts&.fetch('remote_ids', nil)
			end
			params.require(:site).permit(editor_uids: [], permissions: {remote_ids: [], remote_roles: [], locations: []})
		end
	end
end