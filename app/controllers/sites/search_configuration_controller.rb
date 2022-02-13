module Sites
	class SearchConfigurationController < ApplicationController
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
			redirect_to action: :edit
		end

		def edit
		end

		def search_configuration_params
			scp = params.require(:site)
				.require(:search_configuration).permit(
					date_search_configuration: [:enabled, :granularity_search, :show_sidebar, :show_timeline, :sidebar_label],
					map_configuration: [:default_lat, :default_long, :enabled, :granularity_data, :granularity_search, :show_items, :show_sidebar],
					display_options: [:default_search_mode, :show_csv_results, :show_original_file_download, :show_other_sources],
					facets: [:facet_fields_form_value, :label, :limit, :sort, :value_transforms],
					search_fields: [:type, :label]
			)&.to_h
			# todo: find a better way to unroll the list of values
			scp&.tap do |atts|
				atts['search_fields'] = atts['search_fields'].values if atts&.fetch('search_fields', nil)
				atts['facets'] = atts['facets'].values if atts&.fetch('facets', nil)
			end
		end
	end
end