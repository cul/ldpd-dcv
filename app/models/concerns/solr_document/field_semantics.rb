module SolrDocument::FieldSemantics
	def self.included(mod)
		# DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
		# Semantic mappings of solr stored fields. Fields may be multi or
		# single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
		# and Blacklight::Solr::Document#to_semantic_values
		# Recommendation: Use field names from Dublin Core
		mod.use_extension( Blacklight::Document::DublinCore)
		# Normalized field names
		mod.field_semantics.merge!(
			identifier: 'ezid_doi_ssim',
			title: 'title_display_ssm',
			creator: 'primary_name_sim',
			format: 'lib_format_ssm',
			type: 'type_of_resource_ssm',
			subject: 'lib_all_subjects_ssm',
			description: 'abstract_ssm'
		)
	end
end