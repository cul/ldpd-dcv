require 'yaml'
require 'json'

module Dcv::Sites::Export
	class Solr
		include Dcv::Sites::Constants
		def initialize(site)
			@site = site if site.is_a? Site
			@site ||= begin
				Site.find_by(slug: site)
			end
		end
		def exists?
			@site
		end
		def run
			doc = {}
			return doc unless @site
			doc['title_display_ssm'] = [@site.title]
			doc['active_fedora_model_ssi'] = 'Concept'
			doc['lib_repo_code_ssim'] = [@site.repository_id].compact
			doc['restriction_ssim'] = ['yes'] if @site.restricted
			doc['slug_ssim'] = [@site.slug.split('/').first]
			doc['source_ssim'] = @site.persistent_url if @site.persistent_url.present?
			SolrDocument.new(doc)
		end
	end
end