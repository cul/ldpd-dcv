class Dcv::Sites::LocalSearchState < Blacklight::SearchState
	def params_for_search(*args)
		super.except(:site_slug, :slug)
	end

	def reset_search_params
		super.except(:site_slug, :slug)
	end

	def params_for_site(*args)
		params.dup.slice(:site_slug, :slug)
	end

	def doi_params(doc)
		return {} unless doc
		doi_id = doc.fetch('ezid_doi_ssim',[]).first&.sub(/^doi:/,'')
		{ 'id' => doi_id }
	end

	def url_for_document(doc, options = {})
		controller_name = controller.controller_name
		[options, doi_params(doc), params_for_site.compact]
			.reduce('controller' => controller_name, 'action' => :show) {|accum, opts| accum.merge(opts)}
	end
end