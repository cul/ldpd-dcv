module SolrDocument::ArchivalContext
	extend ActiveSupport::Concern

	def archival_context_json(archival_context_field = nil)
		archival_context_field ||= FieldDisplayHelpers::ARCHIVAL_CONTEXT_JSON_FIELD
		@archival_context_jsons ||= {}
		@archival_context_jsons[archival_context_field] ||= begin
			json_srcs = Array.wrap(self.fetch(archival_context_field,'[]'))
			json_srcs.map { |json_src| JSON.load(json_src) }.flatten
		end
	end

	def has_archival_context?(archival_context_field = nil)
		archival_context_json(archival_context_field).detect {|ac| ac['dc:coverage'].present? }
	end

	def archival_contexts(archival_context_field = nil)
		archival_context_field ||= FieldDisplayHelpers::ARCHIVAL_CONTEXT_JSON_FIELD
		@archival_contexts ||= {}
		@archival_contexts[archival_context_field] ||= begin
			archival_context_json(archival_context_field).map do |ac_json|
				::ArchivalContext.new(ac_json)
			end
		end
	end

	def has_collection_bib_links?(archival_context_field = nil)
		archival_context_field ||= FieldDisplayHelpers::ARCHIVAL_CONTEXT_JSON_FIELD
		archival_context_json(archival_context_field).detect do |collection|
			collection.dig('dc:bibliographicCitation', '@id')
		end
	end

	def collection_bib_links(archival_context_field = nil)
		archival_context_field ||= FieldDisplayHelpers::ARCHIVAL_CONTEXT_JSON_FIELD
		archival_context_json(archival_context_field).map do |collection|
			collection.dig('dc:bibliographicCitation', '@id')
		end.compact
	end

	def repository_code
		@repo_code_lookup ||= begin
			repo_code = self['lib_repo_code_ssim']&.first
			repo_fields = ['lib_repo_full_ssim', 'lib_repo_short_ssim']
			repo_fields.each do |field|
				unless repo_code || self[field].blank?
					codes = code_map_for_repo_field(field)
					self[field].each do |repo_value|
						repo_code ||= codes[repo_value]
					end
				end
			end
			repo_code
		end
	end

	def finding_aid_url(bib_id, clio_only: false, deep_link: false)
		return unless self['collection_key_ssim']&.include?(bib_id)

		repo_code = self.repository_code
		repo_slug = I18n.t("cul.archives.arclight_slug.#{repo_code.downcase.sub('-', '')}") if repo_code
		try_finding_aid = repo_slug.present? || self.has_archival_context?
		if try_finding_aid && bib_id && !clio_only
			finding_aid_url = "https://findingaids.library.columbia.edu/archives/cul-#{bib_id}"
			if deep_link && self[FieldDisplayHelpers::ASPACE_PARENT_FIELD].present?
				return "#{finding_aid_url}_aspace_#{Array(self[FieldDisplayHelpers::ASPACE_PARENT_FIELD]).first}"
			end
			finding_aid_url
		else
			"https://clio.columbia.edu/catalog/#{bib_id}" if bib_id
		end
	end

	private

	def code_map_for_repo_field(field)
		ActiveSupport::HashWithIndifferentAccess.new(I18n.t('ldpd.' + field.split('_')[-2] + '.repo').invert)
	end
end