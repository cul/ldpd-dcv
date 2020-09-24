module SolrDocument::Snippets
	extend ActiveSupport::Concern
	SNIPPET_JOINER = '&hellip;'

	def has_snippet?
		return false unless self.solr_response
		self.solr_response.dig('highlighting',self['id'])&.detect { |k,v| v.present? }
	end

	def snippet
		return unless self.solr_response

		self.solr_response.dig('highlighting',self['id'])&.map do |key, arr_value|
			arr_value.present? ? arr_value : []
		end.flatten.join(SNIPPET_JOINER)
	end
end