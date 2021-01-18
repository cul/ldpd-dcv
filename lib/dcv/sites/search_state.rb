class Dcv::Sites::SearchState < Blacklight::SearchState
	def params_for_search(*args)
		super.except(:site_slug, :slug)
	end
	def reset_search_params
		super.except(:site_slug, :slug)
	end
end