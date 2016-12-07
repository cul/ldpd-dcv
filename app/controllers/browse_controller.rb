class BrowseController < ApplicationController
  include Dcv::Catalog::BrowseListBehavior

  before_action :refresh_catalog_browse_lists_cache

  layout 'dcv'

  def index
  	@browse_lists = get_catalog_browse_lists
  end

  def projects
  end

  def names
  end

  def formats
  	@browse_lists = get_catalog_browse_lists
  end

  def libraries
  end

  def dates
  end

  def places
  end
end
