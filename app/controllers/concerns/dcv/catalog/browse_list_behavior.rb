module Dcv::Catalog::BrowseListBehavior
  extend ActiveSupport::Concern

  # Browse list items must be accessible as facets from in solr (i.e. like facets)
  BROWSE_LISTS_KEY = 'browse_lists'
  BROWSE_LISTS = {
    'lib_name_sim' => {:display_label => 'Names'},
    'lib_format_sim' => {:display_label => 'Formats'},
    'lib_repo_sim' => {:display_label => 'Repositories'}
  }

  # Browse List Logic

  def refresh_browse_lists_cache
    Rails.cache.write(BROWSE_LISTS_KEY, get_browse_lists);
  end

  def get_browse_lists

    hash_to_return = {}

    rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']

    BROWSE_LISTS.each do |facet_field_name, options|
      
      response = rsolr.get 'select', :params => {
        :q  => '*:*',
        :qt => 'search',
        :rows => 0,
        :facet => true,
        :'facet.sort' => 'index', # We want Solr to order facets based on their type (alphabetically, numerically, etc.)
        :'facet.field' => [facet_field_name],
        ('f.' + facet_field_name + '.facet.limit').to_sym => -1,
      }

      facet_response = response['facet_counts']['facet_fields'][facet_field_name]
      hash_to_return[facet_field_name] = {}
      hash_to_return[facet_field_name]['display_label'] = options[:display_label]
      hash_to_return[facet_field_name]['value_pairs'] = {}
      facet_response.each_slice(2) do |value, count|
        hash_to_return[facet_field_name]['value_pairs'][value] = count
      end

    end

    return hash_to_return
  end

end
