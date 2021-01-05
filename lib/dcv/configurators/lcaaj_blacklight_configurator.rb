class Dcv::Configurators::LcaajBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'lcaaj' }

    config.default_solr_params = {
      :defType => 'edismax',
      :fq => [
        '-active_fedora_model_ssi:GenericResource'
      ],
      :qt => 'search',
      :rows => 20,
      :mm => 1
    }

    config.per_page = [20,60,100]
    # solr field configuration for search results/index views
    default_index_configuration(config)
    default_show_configuration(config)

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar

    config.add_facet_fields_to_solr_request! # Required for facet queries

    config.add_facet_field ActiveFedora::SolrService.solr_name('role_interviewer', :symbol), :label => 'Interviewer', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('role_interviewee', :symbol), :label => 'Interviewee', :sort => 'index', :limit => 10

    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_region', :symbol), :label => 'Region', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), :label => 'City', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => 'Document Type', :sort => 'index', :limit => 10, :cul_custom_value_transforms => [:translate, :capitalize, :singularize], :cul_custom_value_hide => ['manuscripts'], translation: 'facet.lcaaj.format'
    config.add_facet_field 'has_geo_bsi', :label => 'Geo Data Flag', show: false, limit: 2
    config.add_facet_field 'format_ssi', :label => 'System Format', :sort => 'count' if ['development', 'test', 'dcv_dev', 'dcv_private_dev'].include?(Rails.env)

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.keys
    config.default_solr_params['facet.limit'] = 60
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_repo_long', :symbol, type: :string), :label => 'Library Location'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_name', :displayable, type: :string), label: 'Name', tombstone_display: true
    config.add_index_field ActiveFedora::SolrService.solr_name('location_sublocation', :displayable, type: :string), :label => 'Department'
    config.add_index_field ActiveFedora::SolrService.solr_name('location_shelf_locator', :displayable, type: :string), :label => 'Shelf Location'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_index_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), :label => 'Summary', :helper_method => :truncate_text_to_250
    config.add_index_field 'cul_number_of_members_isi', :label => 'Number of Images'
    #config.add_index_field ActiveFedora::SolrService.solr_name('lib_item_in_context_url', :displayable, type: :string), :label => 'Item in Context', :helper_method => :link_to_url_value

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_repo_full', :symbol, type: :string), :label => 'Library Location', :helper_method => :show_field_repository_to_facet_link
    config.add_show_field ActiveFedora::SolrService.solr_name('role_interviewer', :symbol), :label => 'Interviewer', :sort => 'index', :link_to_search => ActiveFedora::SolrService.solr_name('role_interviewer', :symbol)
    config.add_show_field ActiveFedora::SolrService.solr_name('role_interviewee', :symbol), :label => 'Interviewee', :sort => 'index', :link_to_search => ActiveFedora::SolrService.solr_name('role_interviewee', :symbol)
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), :label => 'Format'
    config.add_show_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_region', :symbol), :label => 'Region'
    config.add_show_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), :label => 'City'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_project_full', :symbol), :label => 'Digital Project'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), :label => 'Collection'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_non_date_notes', :displayable, type: :string), :label => 'Note'
    config.add_show_field ActiveFedora::SolrService.solr_name('location_shelf_locator', :displayable, type: :string), :label => 'Shelf Location'
    config.add_show_field ActiveFedora::SolrService.solr_name('physical_description_extent', :displayable, type: :string), :label => 'Physical Description'
    config.add_show_field ActiveFedora::SolrService.solr_name('identifier', :symbol), :label => 'Identifier'
    config.add_show_field ActiveFedora::SolrService.solr_name('ezid_doi', :symbol), :label => 'DOI', :show => false
    config.add_show_field 'geo', label: 'Coordinates', if: false

    # solr fields to be displayed in the geo/map panels
    #  facetable (link: true)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_neighborhood', :symbol), label: 'Neighborhood', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_borough', :symbol), label: 'Borough', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), label: 'City', link: true
    #  nonfacetable (link: false)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_street', :symbol), label: 'Address', link: false
    config.add_geo_field 'geo', label: 'Coordinates', link: false

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # All Text search configuration, used by main search pulldown.
    config.add_search_field ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text) do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)]
      }
    end

    config.add_search_field ActiveFedora::SolrService.solr_name('search_title_info_search_title', :searchable, type: :text) do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)]
      }
    end

    config.add_search_field ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text) do |field|
      field.label = 'Name'
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)]
      }
    end

    #config.add_search_field ActiveFedora::SolrService.solr_name('search_title_info_search_title', :searchable, type: :text) do |field|
    #  field.label = 'Title'
    #  field.solr_parameters = {
    #    :qf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)],
    #    :pf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)]
    #  }
    #end
    #
    #config.add_search_field ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text) do |field|
    #  field.label = 'Name'
    #  field.solr_parameters = {
    #    :qf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)],
    #    :pf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)]
    #  }
    #end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc', :label => 'relevance'
    config.add_sort_field 'title_si asc', :label => 'title'
    config.add_sort_field 'lib_start_date_year_itsi asc', :label => 'date (earliest to latest)'
    config.add_sort_field 'lib_start_date_year_itsi desc', :label => 'date (latest to earliest)'


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Respond to CSV
    config.index.respond_to.csv = true

  end

end
