module Dcv::Sites::Import
	SITE_METADATA = "properties.yml"
	NAV_LINKS_CSV = "navLinks.csv"
	PAGES_SUBDIR = "pages"

	class Directory
		def initialize(directory)
			@directory = directory if directory.is_a?(Dir)
			@directory ||= begin
				Dir.new(directory) if Dir.exist?(directory)
			end
		end
		def exists?
			@directory && Dir.children(@directory.path).include?(SITE_METADATA)
		end
		def run
			return nil unless exists?
			site_dir = @directory.path
			atts = YAML.load(File.read(File.join(site_dir, SITE_METADATA)))
			puts "importing #{atts['slug']} from #{site_dir}"
			site = Site.find_by(slug: atts['slug']) || Site.new(slug: atts['slug'])
			site.title = atts['title']
			site.search_type = atts['search_type']
			site.layout = atts['layout']
			site.palette = atts['palette']
			site.constraints = atts['constraints']
			site.publisher_uri = atts['uri']
			site.restricted = atts['restricted'] || (atts['slug'] =~ /restricted/)
			site.nav_links.delete_all
			site.site_pages.delete_all
			site.save
			links_path = File.join(site_dir, NAV_LINKS_CSV)
			if File.exists? links_path
				CSV.open(links_path, 'r', headers: true,  header_converters: :symbol) do |csv|
					csv.each.map do |row|
						NavLink.create({site_id: site.id}.merge(row.to_h))
					end
				end
			end
			pages_path = File.join(site_dir, PAGES_SUBDIR)
			if Dir.exists? pages_path
				Dir.children(pages_path).each do |page_name|
					page_path = File.join(pages_path, page_name)
					if Dir.exist?(page_path)
						puts "creating page at #{page_name} for #{site.slug}"
						page = SitePage.create(slug: page_name, site_id: site.id)
						Dir.glob(File.join(page_path,"*.md")).map do |block_path|
							label = File.basename(block_path, ".md")
							label.sub!(/^([\d]+)_/) {|m| m[1] + ':'}
							label.gsub!('_',' ')
							label = label.titlecase

							block = SiteTextBlock.new(sort_label: label, site_page_id: page.id)
							block.markdown = File.read(block_path)
							block.save
						end
					end
				end
			end
			site
		end
	end
end