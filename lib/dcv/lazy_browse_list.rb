module Dcv
	class LazyBrowseList
		# Browse list items must be accessible as facets from in solr (i.e. like facets)
		BROWSE_LISTS_KEY_PREFIX = 'browse_lists_'
		BROWSE_LISTS = {
			'lib_name_sim' => {:display_label => 'Names', :short_description => 'People, corporate bodies and events that are represented in or by our items.'},
			'lib_format_sim' => {:display_label => 'Formats', :short_description => 'Original formats of our digitally-presented items.'},
			'lib_repo_long_sim' => {:display_label => 'Library Locations', :short_description => 'Locations of original items:'}
		}

		def self.browse_lists(controller_name)
			BROWSE_LISTS.map {|facet_name, opts| [facet_name, LazyBrowseList.new(controller_name, facet_name)] }.to_h
		end

		def initialize(controller_name, facet_name)
			@controller_name = controller_name
			@facet_name = facet_name
		end

		def browse_list_cache_key
			@browse_list_cache_key ||= BROWSE_LISTS_KEY_PREFIX + @controller_name + '_' + @facet_name
		end

		def [](key)
			case key.to_s
			when 'value_pairs'
				@value_pairs ||= begin
					refresh_list_cache if ['development', 'test'].include?(Rails.env) || ! Rails.cache.exist?(browse_list_cache_key)
					Rails.cache.read(browse_list_cache_key)
				end
			else
				BROWSE_LISTS[@facet_name][key.to_sym]
			end
		end

		def refresh_list_cache
			rsolr = RSolr.connect :url => YAML.load_file('config/blacklight.yml', aliases: true)[Rails.env]['url']

			values_and_counts = {}

			response = rsolr.get 'select', :params => CatalogController.blacklight_config.default_solr_params.merge({
			  :q  => '*:*',
			  :rows => 0,
			  :facet => true,
			  :'facet.sort' => 'index', # We want Solr to order facets based on their type (alphabetically, numerically, etc.)
			  :'facet.field' => [@facet_name],
			  ('f.' + @facet_name + '.facet.limit').to_sym => -1,
			})

			values_and_counts = {}

			if response.fetch('facet_counts', {}).fetch('facet_fields', {})[@facet_name].present?
				facet_response = response['facet_counts']['facet_fields'][@facet_name]
				facet_response.each_slice(2) do |value, count|
					values_and_counts[value] = count
				end
			end
			Rails.cache.write(browse_list_cache_key, values_and_counts, expires_in: 12.hours);
		end
	end
end