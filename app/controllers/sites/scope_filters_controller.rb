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
			scope_filters_attributes = scope_filter_params['scope_filters_attributes']&.values || []
			if scope_filters_attributes # must permit empty collection to allow deletions
				begin
					@subsite.scope_filters.each do |scope_filter|
						if scope_filters_attributes.first
							scope_filter.update_attributes(scope_filters_attributes.shift)
						else
							scope_filter.delete
						end
					end
					scope_filters_attributes.each { |atts| @subsite.scope_filters << ScopeFilter.new(atts) }
					@subsite.save!
					flash[:notice] = "Scope Updated!"
				rescue ActiveRecord::RecordInvalid => ex
					flash[:alert] = ex.message
				end
			end
			redirect_to action: :edit
		end

		def edit
		end

		def show
			redirect_to action: :edit
		end

		def scope_filter_params
			params.require(:site).permit(scope_filters_attributes: [:filter_type, :value])
		end
	end
end	
