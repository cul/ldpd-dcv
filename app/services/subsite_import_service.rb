
# This service implements the logic for extracting the data from a zipped subsite
# export (created by the subsite_export_service), validating the structure of the
# imported data, and saving the result as DLC data in the ActiveRecord database.
# It creates or updates Site, SitePage(s), NavLink(s), TextBlock(s) models and
# saves any signature-theme-related image assets in the public directory.
# 
# Usage:
# Initialize a new instance by passing an uploaded zip file to the initializer
# (expects an instance of ActionDispatch::Http::UploadedFile). Some initial
# processing will occur in the initializer to locate and load the uploaded site's
# metadata files and retrieve (or create if new) the Site model instance.
# Process the uploaded zip file by calling #import_subsite, which will first
# perform a validation of the uploaded zip file's structure, and then process
# the zip file contents to persist the data to the DLC.
# Changes should be available immediately after running the operation.
# All OS resources are managed by the class and are cleaned up automatically.
# This service uses the rubyzip library to process the uploaded zip file.

# These come from the watermark_uploader.rb and banner_uploader.rb class definitions
ALLOWED_IMAGE_FILENAMES = %w[ signature-banner.png signature.svg ]
MD_REGEX = /\d{2,}_[\w.%]*\.md/

# TODO : bust browser cache for signature-banner and water mark images so that 
#        changes are visible
class SubsiteImportService 
  include Dcv::Sites::Constants

  def initialize(zip_file)
    @zip_file = zip_file
    extract_attributes_from_zip_file
  end

  def import_subsite
    Zip::File.open @zip_file do |zip|
      is_valid = validate_import(zip)
      raise Error unless is_valid
      save_import(zip)
    end
    Rails.logger.debug 'done importing!'
  end

  private
  ########## PRIVATE ATTR ACCESSORS #############
  # This must be called in the initializer
  def extract_attributes_from_zip_file
    puts 'extracting attrs'
    Zip::File.open @zip_file do |zip|
      @pages_metadata_files = zip.glob("#{PAGES_SUBDIR}/**/#{SITE_METADATA}")
      zip.glob(SITE_METADATA).first.get_input_stream do |zis|
        @attrs = YAML.load zis.read
      end
      @site = Site.find_by(slug: @attrs['slug']) || Site.new(slug: @attrs['site'])
    end
  end

  def pages_metadata_files
    @pages_metadata_files
  end

  def attrs
    @attrs
  end

  def site
    @site
  end

  ############## PRIVATE METHODS ################
  def save_import(zip)
    Rails.logger.debug "Importing site #{attrs['slug']}"

    # Create or update Site model
    create_site_model(zip)
    create_nav_links_models(zip)
    create_page_models(zip)
    save_images(zip)

  end

  def save_images(zip)
    puts 'saving images'
    zip_images = zip.glob("#{IMAGES_SUBDIR}/*")
    return if zip_images.length == 0

		image_dir_path = File.join(Rails.root, 'public', 'images', 'sites', site.slug)
    FileUtils.mkdir_p image_dir_path

    zip_images.each do |image_file|
      image_file_name = image_file.name.split('/').last
      next unless ALLOWED_IMAGE_FILENAMES.include? image_file_name
      image_path = "#{image_dir_path}/#{image_file_name}"
      image_file.extract(image_path) { true }
      @site.touch # bust browser cache by updating
      # @site.save
    end
  end

  # Creates each page, each page's images, and each page's text blocks
  def create_page_models(zip)
    puts 'create page models'
    pages_metadata_files.each do |page_metadata_file|
      page_metadata = nil
      page_metadata_file.get_input_stream do |zis|
        page_metadata = YAML.load zis.read
      end

      page_metadata['site_page_images']&.each { |img_attrs| SitePageImage.new(img_attrs) }

      new_page = SitePage.create({
        slug: page_metadata['slug'],
        title: page_metadata['title'],
        site_id: site.id,
        columns: page_metadata['columns'],
      })

      page_metadata['site_page_text_blocks']&.each do |block_attrs|
        markdown_file_name = block_attrs['markdown']
        block_attrs['site_page_images']&.each { |img_attrs| SitePageImage.new(img_attrs) }
        block_attrs['site_page_id'] = new_page.id
        block = SiteTextBlock.new(block_attrs)
        if markdown_file_name =~ MD_REGEX
          # e.g. 'pages/home/00_about_collection.md'
          block.markdown = zip.glob("#{PAGES_SUBDIR}/#{new_page.slug}/#{markdown_file_name}")
        end
        block.save
      end
    end
  end

  def create_nav_links_models(zip)
    nav_links = Array(attrs.delete('nav_links'))
    nav_links.each do |link_attrs|
      NavLink.create({ site_id: site.id }.merge(link_attrs))
    end
  end

  # Build search configuration model and assign to Site
  def create_site_search_configuration(zip)
    search_configuration_attrs = attrs['search_configuration'] || {}
    if attrs['constraints']
      puts "attrs had legacy constraints; will attempt to migrate? : #{search_configuration_attrs['scope_constraints'].nil?}"
      search_configuration_attrs['scope_constraints'] ||= attrs['constraints']
      # i.e. if constraints are defined, they will attempt to be migrated by setting the search_configuration.scope_constraints
      # to constraints -- IF the value search_configuration.scope_constraints is NOT yet set. 
    end
    if search_configuration_attrs['scope_constraints']
      puts "attrs had search_configuration[scope_constraints]; migrate? : #{attrs['scope_filters'].blank?}"
      scope_constraints = search_configuration_attrs.delete('scope_constraints')
      if attrs['scope_filters'].blank?
        attrs['scope_filters'] = []
        scope_constraints.each do |type, values|
          attrs['scope_filters'].concat(values.map { |value| { 'filter_type' => type, 'value' => value } })
        end
      end
      # i.e. if the site import has search_configuration.scope_constraints set to a non-nil value AND the import has
      # a blank value for scope_filters, it will set the scope_filters to be the array of scope_constraints
    end
    site.search_configuration = Site::SearchConfiguration.new(search_configuration_attrs)
  end

  # Uses the attributes from the top-level METADATA_FILE to set attributes for
  # the site model corresponding to the import
  def create_site_model(zip)
    site.title = attrs['title']
    site.alternative_title = attrs['alternative_title']
    site.repository_id = attrs['repository_id']
    site.search_type =  attrs['search_type'] || DEFAULT_SEARCH_TYPE
    site.layout = attrs['layout'] || DEFAULT_LAYOUT
    site.palette = attrs['palette'] || DEFAULT_PALETTE
    site.show_facets = attrs['show_facets'] if attrs['show_facets']
    site.permissions = Site::Permissions.new(attrs['permissions'])
    site.image_uris = attrs['image_uris']
    site.publisher_uri = attrs['publisher_uri']

    create_site_search_configuration(zip)

    # Reset site scope_filters
    site.scope_filters.delete_all
    attrs['scope_filters']&.each { |filter_attrs| site.scope_filters << ScopeFilter.new(filter_attrs) }

    # A restricted site has 'restricted' as the starting chars of its slug
    site.restricted = attrs['restricted'] || (attrs['slug'] =~ /restricted/)

    # Reset nav links and pages
    site.nav_links.delete_all
    site.site_pages.each do |page|
      page.site_text_blocks.delete_all
      page.delete
    end
    site.save!
  end

  def validate_import(zip)
    # top-level metadata file should exit
    return false if zip.glob(SITE_METADATA).length != 1

    # Validate there is a pages/home/ directory
    # N.B. we cannot use the rubyzip glob method to match directories; only file 
    # names to validate that a pages directory and pages/home directory exist, 
    # we will check for pages/home/properties.yml to validate both requirements
    # at once
    return false unless pages_metadata_files.any? { |file| file.name == "#{PAGES_SUBDIR}/home/#{SITE_METADATA}" }

    # Validate that each properties.yml that has site_pages_text_blocks data
    # have the corresponding markdown files
    pages_metadata_files.each do |metadata_file|
      yaml = nil
      metadata_file.get_input_stream do |zis|
        yaml = YAML.load zis.read
      end
      page_slug = yaml["slug"]
      yaml["site_page_text_blocks"].each do |block|
        markdown_file_name = block["markdown"]
        # validate markdown filename format
        return false unless markdown_file_name =~ MD_REGEX
        return false if zip.glob("#{PAGES_SUBDIR}/#{page_slug}/#{markdown_file_name}").length != 1
      end
    end

    # Validate any files in images/ directory are of proper file type
    images = zip.glob("#{IMAGES_SUBDIR}/*")
    images.each do |image|
      return false unless ALLOWED_IMAGE_FILENAMES.include? image.name.split('/').last
    end

    return true
  end
end