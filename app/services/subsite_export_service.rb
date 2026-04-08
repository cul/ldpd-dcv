require 'zip'

# This service implements the logic for creating a zipped "site export", containing
# the content of a DLC subsite.
# 
# It will be available to DLC administrators and subsite editors mainly for the purpose
# of migrating a subsite between DLC host environments (e.g. staging to production).
# It can also be used by DLC developers to retrieve real subsite data from production
# to use during local development.
# 
# The service class should be initialized with an instance of a subsite model and
# an optional boolean db_fields flag that will control the inclusion of ActiveRecord-
# specific attributes in the exported subsite package (created_at, id, etc.).
# 
# An exported site has the following file structure:
#   export_directory/
#    - properties.yml (subsite metadata file)
#    ∟ images/
#       - img1
#       - img2
#       - other images...
#    ∟ pages/
#      ∟ about/
#        - 00_About.md
#        - properties.yml (page metadata file)
#      ∟ home/
#        - 00_About.md
#        - 01_Info.md
#        - properties.yml (page metadata file)
#      ∟ other pages...
#
# Each level of the directory includes a yaml metadata file describing the contents

DB_FIELDS = ['id', 'created_at', 'site_id', 'site_page_id', 'updated_at']

class SubsiteExportService
  include Dcv::Sites::Constants

  def initialize(subsite, db_fields = false)
    @subsite = subsite
    @db_fields = db_fields
  end

  # Users can optionally include ActiveRecord-specific fields by passing db_fields true
  def create_zipped_export
    # For now, let's try to create the zip in memory:
    stream = Zip::OutputStream.write_buffer do |zos|
      write_subsite_metadata(zos)
      write_pages(zos)
      write_images(zos)
    end
    stream.rewind
    stream
  end

  private

  # Include any images stored in the following location:
  # <proj_root>/public/images/sites/<subsite_slug>/
  def write_images(zos)
    images_dir = File.join(Rails.root, 'public', 'images', 'sites', @subsite.slug)
    return unless Dir.exist?(images_dir)
    Dir.new(images_dir).entries.each do |entry|
      if entry =~ /^[a-zA-Z0-9]/
        zos.put_next_entry("#{IMAGES_SUBDIR}/#{entry}")
        open("#{images_dir}/#{entry}") do |image_file|
          zos.write(image_file.read)
        end
      end
    end
  end

  # Creates the top-level metadata properties.yml file
  def write_subsite_metadata(zos)
    zos.put_next_entry(SITE_METADATA)
    json = @subsite.as_json(include: {scope_filters: {}, nav_links: {}, permissions: {compact: true}, search_configuration: {compact: true}})
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
    yaml = YAML.dump(json)
    zos.write(yaml)
  end

  # Create the page metadata file for each subsite's pages, extract the markdown
  # from the page's text block(s), and zip it all up in the correct location
  def write_pages(zos)
    @subsite.site_pages.each do |site_page|
      markdown_files = [] # Collect our markdown files for zipping after doing the metadata file for this page
      current_page_subdir = "#{PAGES_SUBDIR}/#{site_page.slug}/"
      zos.put_next_entry("#{current_page_subdir}#{SITE_METADATA}")
      json = site_page.as_json
      json['site_page_images'] = site_page.site_page_images.map(&:as_json).each do |site_page_image|
        DB_FIELDS.each { |field| site_page_image.delete(field) } # TODO: unless @db_fields ?
        site_page_image.delete('depictable_id')
        site_page_image.delete('depictable_type')
        site_page_image
      end
      DB_FIELDS.each { |field| json.delete(field) } unless @db_fields
      json['site_page_text_blocks'] = []
      site_page.site_text_blocks.each do |text_block|
        block_json = get_site_page_text_block_metadata(text_block)
        page_markdown_filename = SiteTextBlock.export_filename_for_sort_label(text_block.sort_label)
        block_json['markdown'] = page_markdown_filename
        json['site_page_text_blocks'] << block_json
        # Add markdown for text block to array for zipping later
        markdown_files << { filename: page_markdown_filename, markdown: text_block.markdown }
      end
      zos.write(YAML.dump(json))
      # now zip the markdown files that were created from this site_page's text_block(s)
      markdown_files.each do |block_obj|
        zos.put_next_entry("#{current_page_subdir}#{block_obj[:filename]}")
        zos.write(block_obj[:markdown])
      end
    end
  end

  # Extract the metadata for a text_block in a subsite page
  def get_site_page_text_block_metadata(text_block)
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
end