class Dcv::Sites::SearchState < Blacklight::SearchState
	def params_for_search(*args)
		super.except(:slug)
	end

	def reset_search_params
		super.except(:slug)
	end

	def url_for_document(doc, options = {})
		if doc.slug
			params.merge('slug' => doc.slug)
		elsif doc.doi_identifier
			{ controller: 'catalog', id: doc.doi_identifier, action: 'show' }
		else
			params
		end
	end
end