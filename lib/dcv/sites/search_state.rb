class Dcv::Sites::SearchState < Dcv::SearchState
	include Dcv::Sites::Constants

	def params_for_search(*args)
		super.except(:slug)
	end

	def reset_search_params
		super.except(:slug)
	end

	def url_for_document(doc, options = {})
		doc = SolrDocument.new(doc) if doc.is_a? Hash
		if doc.slug
			params.merge('slug' => doc.slug)
		elsif doc.doi_identifier
			params.merge(url_for_doi(doc.doi_identifier, controller.load_subsite))
		else
			params
		end
	end

	def url_for_doi(doi_identifier, site)
		case site.search_type
		when SEARCH_LOCAL
			controller_name = controller.restricted? ? "restricted/sites/search" : "sites/search"
			return { controller: controller_name, site_slug: site.slug, id: doi_identifier, action: 'show', slug: nil }
		when SEARCH_CUSTOM
			return { controller: URI.decode_www_form_component(site.slug), id: doi_identifier, action: 'show', slug: nil }
		else
			return { controller: 'catalog', id: doi_identifier, action: 'show', slug: nil }
		end
	end
end