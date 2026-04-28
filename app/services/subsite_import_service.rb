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

# These filename constants come from the watermark_uploader.rb and banner_uploader.rb class definitions
ALLOWED_IMAGE_FILENAMES = %w[signature-banner.png signature.svg]
MD_REGEX = /\d{2,}_[\w.%]*\.md/

class SubsiteImportService
  include Dcv::Sites::Constants
  attr_reader :finish_message

  def initialize(zip_file, is_admin)
    @zip_file = zip_file
    @is_admin = is_admin
    extract_attributes_from_zip_file
  end

  def import_subsite
    Rails.logger.debug "Importing subsite: #{@site.title} at #{@site.slug}"
    Zip::File.open @zip_file do |zip|
      validate_import(zip)
      save_import(zip)
    end
    Rails.logger.debug "Done importing subsite: #{@site.title} at #{@site.slug}"
  rescue StandardError => e
    raise e if e.is_a? Exceptions::SubsiteUploadValidationError

    raise Exceptions::SubsiteUploadError.new("(#{e.class}) #{e.message}")
  end

  private

  ########## PRIVATE ATTR ACCESSORS #############
  # This must be called in the initializer
  def extract_attributes_from_zip_file
    Zip::File.open @zip_file do |zip|
      @pages_metadata_files = zip.glob("#{PAGES_SUBDIR}/**/#{SITE_METADATA}")
      if zip.glob(SITE_METADATA).length != 1
        raise Exceptions::SubsiteUploadValidationError.new("No home page metadata file could be located (#{zip.glob(SITE_METADATA).length} results found for '#{SITE_METADATA})")
      end

      zip.glob(SITE_METADATA).first.get_input_stream do |zis|
        @attrs = YAML.load zis.read
      end
      new_subsite = Site.find_by(slug: @attrs['slug']).nil?
      if new_subsite && !@is_admin
        raise Exceptions::SubsiteUploadError.new('You are not authorized to import a new site to the DLC. If this is an error, please contact a DLC administrator to receive admin privileges.')
      end

      @finish_message = "#{new_subsite ? 'Created new' : 'Updated'} DLC subsite at /#{@attrs['slug']}!"
      @site = Site.find_by(slug: @attrs['slug']) || Site.new(slug: @attrs['slug'])
    end
  end

  attr_reader :pages_metadata_files, :attrs, :site

  ############## PRIVATE METHODS ################
  def save_import(zip)
    create_site_model(zip)
    create_nav_links_models(zip)
    create_page_models(zip)
    save_images(zip)
  end

  def save_images(zip)
    zip_images = zip.glob("#{IMAGES_SUBDIR}/*")
    return if zip_images.empty?

    image_dir_path = File.join(Rails.root, 'public', 'images', 'sites', site.slug)
    FileUtils.mkdir_p image_dir_path

    zip_images.each do |image_file|
      image_file_name = image_file.name.split('/').last
      next unless ALLOWED_IMAGE_FILENAMES.include? image_file_name

      image_path = "#{image_dir_path}/#{image_file_name}"
      image_file.extract(image_path) { true }
    end
  end

  # Creates each page, each page's images, and each page's text blocks
  def create_page_models(zip)
    pages_metadata_files.each do |page_metadata_file|
      page_metadata = nil
      page_metadata_file.get_input_stream do |zis|
        page_metadata = YAML.load zis.read
      end

      page_metadata['site_page_images']&.each { |img_attrs| SitePageImage.new(img_attrs) }

      new_page = SitePage.create!(
        {
          slug: page_metadata['slug'],
          title: page_metadata['title'],
          site_id: site.id,
          columns: page_metadata['columns']
        }
      )

      page_metadata['site_page_text_blocks']&.each do |block_attrs|
        markdown_file_name = block_attrs['markdown']
        block_attrs['site_page_images']&.each { |img_attrs| SitePageImage.new(img_attrs) }
        block_attrs['site_page_id'] = new_page.id
        block = SiteTextBlock.new(block_attrs)
        if markdown_file_name =~ MD_REGEX
          # e.g. 'pages/home/00_about_collection.md'
          block.markdown = zip.glob("#{PAGES_SUBDIR}/#{new_page.slug}/#{markdown_file_name}")
        end
        block.save!
      end
    end
  end

  def create_nav_links_models(zip)
    nav_links = Array(attrs.delete('nav_links'))
    nav_links.each do |link_attrs|
      NavLink.create!({ site_id: site.id }.merge(link_attrs))
    end
  end

  # Build search configuration model and assign to Site
  def create_site_search_configuration(zip)
    search_configuration_attrs = attrs['search_configuration'] || {}
    if attrs['constraints']
      Rails.logger.debug "attrs had legacy constraints; will attempt to migrate? : #{search_configuration_attrs['scope_constraints'].nil?}"
      search_configuration_attrs['scope_constraints'] ||= attrs['constraints']
      # i.e. if constraints are defined, they will attempt to be migrated by setting the search_configuration.scope_constraints
      # to constraints -- IF the value search_configuration.scope_constraints is NOT yet set.
    end
    if search_configuration_attrs['scope_constraints']
      Rails.logger.debug "attrs had search_configuration[scope_constraints]; migrate? : #{attrs['scope_filters'].blank?}"
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
    site.search_type = attrs['search_type'] || DEFAULT_SEARCH_TYPE
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

  # If the uploaded zip file fails any validations, raises a descriptive Subsite
  # Upload Validation Error.
  # Validation rules:
  #   - has a subsite meta data file at the top level
  #   - has a home page
  #   - each subsite page has a meta data file in a subdirectory
  #   - if a page has text blocks, those text blocks have a corresponding markdown
  #     file included in the upload
  #   - if there are image uploads, the images are in the correct location and
  #     have the proper filenames and extensions
  def validate_import(zip)
    # top-level metadata file should exit
    if zip.glob(SITE_METADATA).length != 1
      raise Exceptions::SubsiteUploadValidationError.new("There should be one top-level site metadata file. We found #{zip.glob(SITE_METADATA).length}")
    end

    # Validate there is a pages/home/ directory
    # N.B. we cannot use the rubyzip glob method to match directories; only file
    # names to validate that a pages directory and pages/home directory exist,
    # we will check for pages/home/properties.yml to validate both requirements
    # at once
    unless pages_metadata_files.any? { |file| file.name == "#{PAGES_SUBDIR}/home/#{SITE_METADATA}" }
      raise Exceptions::SubsiteUploadValidationError.new('No home page data was found (subsites must have a home page with a proper metadata file).')
    end

    # Validate that each properties.yml that has site_pages_text_blocks data
    # have the corresponding markdown files
    pages_metadata_files.each do |metadata_file|
      yaml = nil
      metadata_file.get_input_stream do |zis|
        yaml = YAML.load zis.read
      end
      page_slug = yaml['slug']
      yaml['site_page_text_blocks'].each do |block|
        markdown_file_name = block['markdown']
        # validate markdown filename format
        unless markdown_file_name =~ MD_REGEX
          raise Exceptions::SubsiteUploadValidationError.new("A page text block markdown file has the wrong filename (offender: #{markdown_file_name})")
        end
        if zip.glob("#{PAGES_SUBDIR}/#{page_slug}/#{markdown_file_name}").length != 1
          raise Exceptions::SubsiteUploadValidationError.new("Could not locate a page text block's markdown file (#{zip.glob("#{PAGES_SUBDIR}/#{page_slug}/#{markdown_file_name}").length} results for '#{"#{PAGES_SUBDIR}/#{page_slug}/#{markdown_file_name}"}')")
        end
      end
    end

    # Validate any files in images/ directory are of proper file type
    images = zip.glob("#{IMAGES_SUBDIR}/*")
    images.each do |image|
      unless ALLOWED_IMAGE_FILENAMES.include? image.name.split('/').last
        raise Exceptions::SubsiteUploadValidationError.new("The uploaded signature image has the wrong file type or name. Found: #{image.name.split('/').last} - allowed names/types: #{ALLOWED_IMAGE_FILENAMES}")
      end
    end
  end
end
