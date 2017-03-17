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
    refresh_catalog_browse_lists_cache if Rails.env == 'development' || ! Rails.cache.exist?(browse_lists_cache_key)
    @browse_lists =  Rails.cache.read(browse_lists_cache_key)
  end

  def refresh_catalog_browse_lists_cache
    if Rails.env == 'development' || ! Rails.cache.exist?(browse_lists_cache_key)
      Rails.cache.write(browse_lists_cache_key, generate_catalog_browse_lists, expires_in: 24.hours);
    end
  end

  def generate_catalog_browse_lists
    hash_to_return = {}

    BROWSE_LISTS.each do |facet_field_name, options|
      hash_to_return[facet_field_name] = get_all_catalog_facet_values_and_counts(facet_field_name)
      hash_to_return[facet_field_name]['display_label'] = options[:display_label]
      hash_to_return[facet_field_name]['short_description'] = options[:short_description]
    end

    return hash_to_return
  end

  def get_all_catalog_facet_values_and_counts(facet_field_name)
    rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']

    values_and_counts = {}

    response = rsolr.get 'select', :params => CatalogController.blacklight_config.default_solr_params.merge({
      :q  => '*:*',
      :rows => 0,
      :'facet.sort' => 'index', # We want Solr to order facets based on their type (alphabetically, numerically, etc.)
      :'facet.field' => [facet_field_name],
      ('f.' + facet_field_name + '.facet.limit').to_sym => -1,
    })

		values_and_counts['value_pairs'] = {}

		if response.fetch('facet_counts', {}).fetch('facet_fields', {})[facet_field_name].present?
			facet_response = response['facet_counts']['facet_fields'][facet_field_name]
			facet_response.each_slice(2) do |value, count|
				values_and_counts['value_pairs'][value] = count
			end
		end

    return values_and_counts

  end

end
