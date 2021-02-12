module Dcv::Sites::Import
	class Solr
		include Dcv::Sites::Constants
		def self.exists?(document)
			puts document unless document[:slug_ssim].present?
			document[:slug_ssim].present?
		end
		def initialize(document)
			@document = document.is_a?(SolrDocument) ? document : SolrDocument.new(document)
		end
		def exists?
			self.class.exists?(@document)
		end
		def run
			return nil unless exists?
			restricted = @document.has_restriction?
			slug = @document.slug
			existing_site = Site.exists?(slug: slug)
			site = existing_site ? Site.find_by(slug: slug) : Site.new(slug: slug)

			site.publisher_uri ||= @document[:fedora_pid_uri_ssi]
			site.image_uris = Array(@document[:schema_image_ssim]) if site.image_uris.blank?
			site.repository_id = @document[:lib_repo_code_ssim]&.first
			site.title = Array(@document[:title_ssm]).first if @document[:title_ssm].present?
			site.persistent_url = @document.persistent_url if @document.persistent_url
			site.restricted = restricted

			subsite_config = SubsiteConfig.for_path(slug, restricted).freeze

			# constraints and layout depend on whether it is a configured subsite or not
			if subsite_config.present?
				site.search_type = 'custom'
				import_legacy_scope_configs(site, subsite_config)
				import_legacy_layout_configs(site, subsite_config)
				unless existing_site
					# on first import, seed scope if present
					import_legacy_search_configs(site, subsite_config)
				end
			else
				site.search_type ||= 'catalog'
				site.layout ||= DEFAULT_LAYOUT
				site.palette ||= DEFAULT_PALETTE
				unless existing_site
					# on first import, seed scope if present
					facet_value = Array(@document.fetch(:short_title_ssim,[])).first
					if facet_value
						search_scope = @document.fetch(:search_scope_ssi, "project")
						site.scope_filters << ScopeFilter.new(filter_type: search_scope, value: facet_value)
					end
				end
			end

			unless site.save
				puts "failed to import #{slug}:\n\t#{site.errors.inspect}"
			end
			if existing_site
				return site
			end
			# on first import, seed alternative title
			site.alternative_title = Array(@document[:alternative_title_ssm]).first if @document[:alternative_title_ssm].present?
			# on first import, seed the home and about page text blocks, links
			seed_site_pages(site, @document)

			# add links
			seed_secondary_navigation(site, @document)
			site
		end

		def seed_site_pages(site, solr_document)
			home_page = SitePage.new(slug: 'home', site_id: site.id)
			home_page.save
			# add home page block
			if solr_document['description_text_ssm'].blank?
				home_block = Array(solr_document['abstract_ssim']).join
			else
				home_block = Array(solr_document['description_text_ssm']).join
			end
			block_title = "About #{Array(solr_document[:short_title_ssim]).first || site.title}"
			SiteTextBlock.new(sort_label: "00:#{block_title}", markdown: home_block, site_page_id: home_page.id).save
			# add about page block
			about_page = SitePage.new(slug: 'about', site_id: site.id, title: block_title)
			about_page.save
			SiteTextBlock.new(sort_label: "00:", markdown: home_block, site_page_id: about_page.id).save
		end

		def seed_secondary_navigation(site, solr_document)
			locations = solr_document.solr_url_hash(exclude: {'usage' => "primary display"})
			locations.each_with_index do |location, ix|
				nav_link = NavLink.new(site_id: site.id)
				nav_link.link = location['url']
				nav_link.external = true
				nav_link.sort_label = ("%02d:#{location.fetch('displayLabel',"Related Web Content")}" % ix)
				nav_link.sort_group = ("00:See Also")
				nav_link.save
			end
		end

		def import_legacy_layout_configs(site, subsite_config)
			return unless subsite_config.present?
			if subsite_config['layout'].present?
				if VALID_LAYOUTS.include?(subsite_config['layout'])
					site.layout = subsite_config['layout']
				else
					site.layout ||= CUSTOM_LAYOUT
				end
			else
				site.layout = DEFAULT_LAYOUT
			end
			if subsite_config['palette'].present?
				site.palette = subsite_config['palette']
			else
				site.palette ||= DEFAULT_PALETTE
			end
		end

		def import_legacy_scope_configs(site, subsite_config)
			return unless subsite_config.present?
			legacy_constraints = []
			legacy_constraints.concat [site.publisher_uri, subsite_config['uri']]
			legacy_constraints.concat(subsite_config.fetch('additional_publish_targets', []))
			legacy_constraints.compact!
			legacy_constraints.uniq!
			legacy_constraints -= site.publisher_constraints
			if legacy_constraints.present?
				legacy_constraints.each { |value| site.scope_filters << ScopeFilter.new(filter_type: 'publisher', value: value) }
			end
		end

		def import_legacy_search_configs(site, subsite_config)
			return unless subsite_config.present?

			SubsiteConfig.new(subsite_config).tap do |legacy_config|
				if legacy_config.map_configuration.enabled
					site.search_configuration.map_configuration = legacy_config.map_configuration
				end
				if legacy_config.date_search_configuration.enabled
					site.search_configuration.date_search_configuration = legacy_config.date_search_configuration
				end
				site.search_configuration.display_options = legacy_config.display_options
			end
		end
	end
end