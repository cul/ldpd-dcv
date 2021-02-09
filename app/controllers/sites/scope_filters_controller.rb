module Sites
	class ScopeFiltersController < ApplicationController
		include Dcv::RestrictableController
		include Cul::Omniauth::AuthorizingController
		before_filter :load_subsite
		before_filter :authorize_site_update
		layout 'sites'

		def load_subsite
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				Site.find_by(slug: site_slug)
			end
		end

		def update
		end

		def edit
		end

		def show
			redirect_to action: :edit
		end

		def scope_filter_params
		end
	end
end	
