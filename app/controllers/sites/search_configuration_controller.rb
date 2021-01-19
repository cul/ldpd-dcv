module Sites
	class SearchConfigurationController < ApplicationController
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
			begin
				update_attributes = search_configuration_params
				@subsite.search_configuration.assign_attributes update_attributes
				@subsite.save! if @subsite.changed?
				flash[:notice] = "Saved!"
			rescue ActiveRecord::RecordInvalid => ex
				flash[:alert] = ex.message
			end
			@subsite.save! if @subsite.changed?
			if restricted?
				redirect_to edit_restricted_site_search_configuration_path(site_slug: @subsite.slug.sub('restricted/', ''))
			else
				redirect_to edit_site_search_configuration_path(site_slug: @subsite.slug)
			end
		end

		def show
			edit
		end

		def edit
		end

		#TODO: strengthen params after Rails 5+ for deep hashes
		def search_configuration_params
			params.dig('site', 'search_configuration')&.tap do |atts|
				atts['search_fields'] = atts['search_fields'].values if atts&.fetch('search_fields', nil)
				atts['facets'] = atts['facets'].values if atts&.fetch('facets', nil)
			end
		end
	end
end