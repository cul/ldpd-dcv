module Dcv::Sites::Import
	class Directory
		include Dcv::Sites::Constants
		def initialize(directory)
			@directory = directory if directory.is_a?(Dir)
			@directory ||= begin
				Dir.new(directory) if Dir.exist?(directory)
			end
		end
		def exists?
			@directory && Dir.entries(@directory.path).include?(SITE_METADATA)
		end
		def atts
			@atts ||= YAML.load(File.read(File.join(@directory.path, SITE_METADATA)))
		end
		def run
			return nil unless exists?
			site_dir = @directory.path
			puts "importing #{atts['slug']} from #{site_dir}"
			site = Site.find_by(slug: atts['slug']) || Site.new(slug: atts['slug'])
			site.title = atts['title']
			site.alternative_title = atts['alternative_title']
			site.repository_id = atts['repository_id']
			site.search_type = atts['search_type'] if atts['search_type']
			site.search_type ||= DEFAULT_SEARCH_TYPE
			site.layout = atts['layout'] if atts['layout']
			site.layout ||= DEFAULT_LAYOUT
			site.palette = atts['palette'] if atts['palette']
			site.palette ||= DEFAULT_PALETTE
			site.show_facets = atts['show_facets'] if atts['show_facets']
			search_configuration_atts = atts['search_configuration'] || {}
			if atts['constraints']
				puts "atts had legacy constraints; will attempt to migrate? : #{search_configuration_atts['scope_constraints'].nil?}"
				search_configuration_atts['scope_constraints'] ||= atts['constraints']
			end
			if search_configuration_atts['scope_constraints']
				puts "atts had search_configuration[scope_constraints]; migrate? : #{atts['scope_filters'].blank?}"
				scope_constraints = search_configuration_atts.delete('scope_constraints')
				if atts['scope_filters'].blank?
					atts['scope_filters'] = []
					scope_constraints.each do |type, values|
						atts['scope_filters'].concat(values.map {|value| {'filter_type' => type, 'value' => value} })
					end
				end
			end
			site.search_configuration = Site::SearchConfiguration.new(search_configuration_atts)
			site.permissions = Site::Permissions.new(atts['permissions'])
			site.scope_filters.delete_all
			atts['scope_filters']&.each {|filter_atts| site.scope_filters << ScopeFilter.new(filter_atts)}
			site.image_uris = atts['image_uris']
			site.publisher_uri = atts['publisher_uri']
			site.restricted = atts['restricted'] || (atts['slug'] =~ /restricted/)
			site.nav_links.delete_all
			site.site_pages.each do |page|
				page.site_text_blocks.delete_all
				page.delete
			end
			site.save!
			nav_links = Array(atts.delete('nav_links'))
			nav_links.each do |link_atts|
				NavLink.create({site_id: site.id}.merge(link_atts))
			end
			pages_path = File.join(site_dir, PAGES_SUBDIR)
			if Dir.exists? pages_path
				Dir.entries(pages_path).each do |page_name|
					next unless page_name =~ /[^\.]/
					page_path = File.join(pages_path, page_name)
					if Dir.exist?(page_path)
						puts "creating page at #{page_name} for #{site.slug}"
						atts = { 'slug' => page_name, 'site_id' => site.id }
						if File.exist?(File.join(page_path, SITE_METADATA))
							atts.merge!(YAML.load(File.read(File.join(page_path, SITE_METADATA))))
						end
						page = SitePage.create(atts)
						Dir.glob(File.join(page_path,"*.md")).map do |block_path|
							label = SiteTextBlock.sort_label_from_filename(block_path)
							block = SiteTextBlock.new(sort_label: label, site_page_id: page.id)
							block.markdown = File.read(block_path)
							block.save
						end
					end
				end
			end
			image_import_path = File.join(site_dir, IMAGES_SUBDIR)
			if Dir.exists?(image_import_path) && !Dir.empty?(image_import_path)
				image_dir_path = File.join(Rails.root, 'public', 'images', 'sites', site.slug)
				FileUtils.mkdir_p(image_dir_path)
				Dir.glob(File.join(image_import_path, '*.*')).each do |src_path|
					dest_path = File.join(image_dir_path, File.basename(src_path))
					FileUtils.cp(src_path, dest_path)
				end
			end

			site.reload
		end
	end
end