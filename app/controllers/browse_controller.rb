class BrowseController < ApplicationController
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::CatalogLayout

  layout Proc.new { |controller|
    controller.subsite_layout
  }

  before_action :meta_nofollow!, only: [:list]
  before_action :meta_noindex!, only: [:list]

  def initialize(*args)
    super(*args)
    # _prefixes are where view path lookups are attempted; probably unnecessary
    # but need testing. default blank value should be first, but layout needs to be in front of controller path
    self._prefixes.unshift "shared"
    self._prefixes.unshift self.subsite_layout
    self._prefixes.unshift self.subsite_key
    self._prefixes.unshift ""
  end

  # view paths look up partial templates within _prefixes
  # paths are relative to Rails.root
  # prepending because we want to give specialized path priority
  prepend_view_path('app/views/browse')
  def set_view_path
    self.prepend_view_path('app/views/' + self.subsite_layout)
  end

  def list
    if ['names', 'formats', 'libraries'].include? params[:list_id].to_s
      @browse_lists = get_catalog_browse_lists
      render params[:list_id]
    else
      render status: 500
    end
  end

  def names
    @browse_lists = get_catalog_browse_lists
  end

  def formats
  	@browse_lists = get_catalog_browse_lists
  end

  def libraries
    @browse_lists = get_catalog_browse_lists
  end
end
