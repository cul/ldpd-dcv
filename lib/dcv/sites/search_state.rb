class Dcv::Sites::SearchState < Blacklight::SearchState
	def params_for_search(*args)
		super.except(:slug)
	end

	def reset_search_params
		super.except(:slug)
	end

	def url_for_document(doc, options = {})
		return params unless doc.slug
		params.merge('slug' => doc.slug)
	end
end