class Dcv::SearchState < Blacklight::SearchState
	def doi_params(doc)
		return {} unless doc
		doi_id = doc.fetch('ezid_doi_ssim',[]).first&.sub(/^doi:/,'')
		{ 'id' => doi_id }
	end

	def url_for_document(doc, options = {})
		options = { only_path: false }.merge(options)
		doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
		if doc.is_a?(SolrDocument) && doc.site_result?
			slug = doc.unqualified_slug
			nested = slug =~ /\//
			controller_name = doc.has_restriction? ? 'restricted/sites' : 'sites'
			{ 'controller' => controller_name, 'action' => 'home', 'slug' => slug }
		else
			super(doc, options)
		end
	end
end