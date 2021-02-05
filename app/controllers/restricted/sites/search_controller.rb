class Restricted::Sites::SearchController < ::Sites::SearchController
	def load_subsite
		@subsite ||= begin
			site_slug = params[:site_slug] || params[:slug]
			site_slug = "restricted/#{site_slug}"
			s = Site.includes(:nav_links).find_by(slug: site_slug)
			s&.configure_blacklight!
			s
		end
	end
	def search_action_url(options = {})
		slug_param = load_subsite.slug.sub("restricted/",'')
		restricted_site_search_url(slug_param, options.except(:controller, :action))
	end
	def tracking_method
		"restricted_site_track_path"
	end
end