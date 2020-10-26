module Dcv::Sites::Import
	class Solr
		include Dcv::Sites::Constants
		def self.exists?(document)
			document[:slug_ssim].present?
		end
		def initialize(document)
			@document = document
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
			site.title = @document[:title_ssm].first if @document[:title_ssm].present?
			site.persistent_url = @document.persistent_url if @document.persistent_url
			site.restricted = restricted

			subsite_config = SubsiteConfig.for_path(slug, restricted)

			# constraints and layout depend on whether it is a configured subsite or not
			if subsite_config.present?
				site.search_type = 'local'
				publisher_constraints = [@document[:fedora_pid_uri_ssi] || subsite_config['uri']]
				publisher_constraints.concat(subsite_config['additional_publish_targets'] || [])
				publisher_constraints.compact!
				site.publisher_constraints = publisher_constraints if publisher_constraints.present?
				if subsite_config['layout'].present?
					site.layout = subsite_config['layout']
				else
					site.layout ||= DEFAULT_LAYOUT
				end
				if subsite_config['palette'].present?
					site.palette = subsite_config['palette']
				else
					site.palette ||= DEFAULT_PALETTE
				end
			else
				site.search_type = 'catalog'
				site.layout ||= DEFAULT_LAYOUT
				site.palette ||= DEFAULT_PALETTE
				search_scope = @document.fetch(:search_scope_ssi, "project")
				facet_value = @document.fetch(:short_title_ssim,[]).first
				if search_scope == 'collection'
					site.collection_constraints = [facet_value]
				elsif search_scope == 'publisher'
					site.publisher_constraints = [site.publisher_uri]
				else
					site.project_constraints = [facet_value]
				end
			end

			site.save
			if existing_site
				return site
			end

			# on first import, seed alternative title
			site.alternative_title = @document[:alternative_title_ssm].first if @document[:alternative_title_ssm].present?
			# on first import, seed the home and about page text blocks, links
			home_page = SitePage.new(slug: 'home', site_id: site.id)
			home_page.save
			# add home page block
			if @document['description_text_ssm'].blank?
				home_block = Array(@document['abstract_ssim']).join
			else
				home_block = Array(@document['description_text_ssm']).join
			end
			block_title = "About #{@document[:short_title_ssim]&.first || site.title}"
			SiteTextBlock.new(sort_label: "00:#{block_title}", markdown: home_block, site_page_id: home_page.id).save
			# add about page block
			about_page = SitePage.new(slug: 'about', site_id: site.id, title: block_title)
			about_page.save
			SiteTextBlock.new(sort_label: "00:", markdown: home_block, site_page_id: about_page.id).save

			# add links
			locations = @document.solr_url_hash(exclude: {'usage' => "primary display"})
			locations.each_with_index do |location, ix|
				nav_link = NavLink.new(site_id: site.id)
				nav_link.link = location['url']
				nav_link.external = true
				nav_link.sort_label = ("%02d:#{location.fetch('displayLabel',"Related Web Content")}" % ix)
				nav_link.sort_group = ("00:See Also")
				nav_link.save
			end
			site
		end
	end
end