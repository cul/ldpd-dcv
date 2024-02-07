# -*- encoding : utf-8 -*-
module Dcv::Catalog::BrowseListBehavior
  extend ActiveSupport::Concern

  # Browse List Logic

  def browse_lists_cache_key
		return Dcv::LazyBrowseList::BROWSE_LISTS_KEY_PREFIX + controller_name
	end

  def get_catalog_browse_lists
    @browse_lists = Dcv::LazyBrowseList.browse_lists(controller_name)
  end
end
