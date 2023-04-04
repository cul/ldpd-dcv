require 'yaml'
require 'json'

module Dcv::Sites::Export
	DB_FIELDS = ['id', 'created_at', 'site_id', 'site_page_id', 'updated_at']
	class Directory
		include Dcv::Sites::Constants
		def initialize(site, directory, db_fields = false)
			@site = site if site.is_a? Site
			@site ||= begin
				Site.find_by(slug: site)
			end
			@directory = directory if directory.is_a?(Dir)
			@directory ||= begin
				FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
				Dir.new(directory)
			end
			@db_fields = db_fields
		end
		def exists?
			metadata_path = File.join(@directory, SITE_METADATA)
			if File.exist?(metadata_path)
				@site && File.writable?(metadata_path)
			else
				@site && File.writable?(@directory.path)
			end
		end
		def run
			open(File.join(@directory, SITE_METADATA), 'wb') do |io|
				json = @site.as_json(include: {scope_filters: {}, nav_links: {}, permissions: {compact: true}, search_configuration: {compact: true}})
				unless @db_fields
					DB_FIELDS.each { |f| json.delete(f) }
					json.delete('constraints') # obsolete
					json['scope_filters'].each do |filter|
						DB_FIELDS.each { |f| filter.delete(f) }
						filter.delete('scopeable_id')
						filter.delete('scopeable_type')
					end
					json['nav_links'].each do |nav_link|
						DB_FIELDS.each { |f| nav_link.delete(f) }
					end
				end
				YAML.dump(json, io)
			end
			pages_export_dir = File.join(@directory, PAGES_SUBDIR)
			FileUtils.mkdir_p(pages_export_dir)
			# dump page content and properties
			@site.site_pages.each do |site_page|
				export_site_page(site_page, pages_export_dir)
			end
			exported_images_dir = File.join(@directory, IMAGES_SUBDIR)
			FileUtils.mkdir_p(exported_images_dir)
			exported_images_dir = Dir.new(exported_images_dir)
			# copy uploaded images
			current_images_dir = File.join(Rails.root, 'public', 'images', 'sites', @site.slug)
			Dir.new(current_images_dir).entries.each do |entry|
				if entry =~ /^[a-zA-Z0-9]/
					FileUtils.copy_entry(File.join(current_images_dir, entry), File.join(exported_images_dir, entry))
				end
			end if Dir.exist?(current_images_dir)
			@directory
		end

		def export_site_page(site_page, pages_export_dir)
			site_page_path = File.join(pages_export_dir, site_page.slug)
			FileUtils.mkdir_p(site_page_path)
			open(File.join(site_page_path, SITE_METADATA), 'wb') do |io|
				json = site_page.as_json
				json['site_page_images'] = site_page.site_page_images.map(&:as_json).each do |spi|
					DB_FIELDS.each { |f| spi.delete(f) }
					spi.delete('depictable_id')
					spi.delete('depictable_type')
					spi
				end
				DB_FIELDS.each { |f| json.delete(f) } unless @db_fields
				json['site_page_text_blocks'] = []
				site_page.site_text_blocks.each do |text_block|
					block_json = export_site_page_text_block_metadata(text_block)
					filename = SiteTextBlock.export_filename_for_sort_label(text_block.sort_label)
					markdown_path = File.join(site_page_path, filename)
					export_site_page_text_block_markdown(text_block, markdown_path)
					block_json['markdown'] = filename
					json['site_page_text_blocks'] << block_json
				end
				YAML.dump(json, io)
			end
		end

		def export_site_page_text_block_metadata(text_block)
			block_json = text_block.as_json
			block_json.delete('markdown')
			DB_FIELDS.each { |f| block_json.delete(f) } unless @db_fields
			block_json['site_page_images'] = text_block.site_page_images.map do |spi|
				spi_json = spi.as_json
				DB_FIELDS.each { |f| spi_json.delete(f) } unless @db_fields
				spi_json.delete('depictable_id')
				spi_json.delete('depictable_type')
				spi_json
			end
			block_json.delete('site_page_images') if block_json['site_page_images'].empty?
			block_json
		end

		def export_site_page_text_block_markdown(text_block, markdown_path)
			filename = SiteTextBlock.export_filename_for_sort_label(text_block.sort_label)
			open(markdown_path, 'wb') { |blio| blio.write(text_block.markdown) }
		end
	end
end