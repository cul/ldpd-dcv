class Dcv::Sites::LocalSearchState < Dcv::SearchState
	def params_for_search(*args)
		super.except(:site_slug, :slug)
	end

	def reset_search_params
		super.except(:site_slug, :slug)
	end

	def params_for_site(*args)
		params.dup.slice(:site_slug, :slug)
	end

	def url_for_document(doc, options = {})
		[options, doi_params(doc), params_for_site.compact]
			.reduce('controller' => controller.controller_path, 'action' => :show) {|accum, opts| accum.merge(opts)}
	end
end