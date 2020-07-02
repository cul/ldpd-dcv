module Dcv::Sites
	module Constants
		# import/export structure constants
		SITE_METADATA = "properties.yml"
		IMAGES_SUBDIR = "images"
		PAGES_SUBDIR = "pages"
		# default property values
		DEFAULT_SEARCH_TYPE = 'catalog'
		DEFAULT_LAYOUT = 'portrait'
		DEFAULT_PALETTE = 'monochromeDark'
	end
	autoload :Export, 'dcv/sites/export'
	autoload :Import, 'dcv/sites/import'
end