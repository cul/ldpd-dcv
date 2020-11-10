# -*- encoding : utf-8 -*-
module Dcv::Catalog::BrowseListBehavior
  extend ActiveSupport::Concern

  # Browse list items must be accessible as facets from in solr (i.e. like facets)
  BROWSE_LISTS_KEY_PREFIX = 'browse_lists_'
  BROWSE_LISTS = {
    'lib_name_sim' => {:display_label => 'Names', :short_description => 'People, corporate bodies and events that are represented in or by our items.'},
    'lib_format_sim' => {:display_label => 'Formats', :short_description => 'Original formats of our digitally-presented items.'},
    'lib_repo_long_sim' => {:display_label => 'Library Locations', :short_description => 'Locations of original items:'}
  }

  # Browse List Logic

  def browse_lists_cache_key
		return BROWSE_LISTS_KEY_PREFIX + controller_name
	end

  def get_catalog_browse_lists
    @browse_lists = Dcv::LazyBrowseList.browse_lists(controller_name)
  end
end
