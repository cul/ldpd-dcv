module Sites
	class SearchConfigurationController < ApplicationController
		before_filter :load_subsite
		before_filter :authorize_site_update

		def load_subsite
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
			end
		end
		def update
		end
		def edit
		end
	end
end