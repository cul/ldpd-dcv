class Dcv::Configurators::CarnegieBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'carnegie' }

    default_default_solr_params(config)

    default_paging_configuration(config)

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

    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_name', :facetable), :label => 'Names', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_topic', :facetable), :label => 'Topics', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('role_interviewee', :symbol), :label => 'Oral Histories', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => 'Formats', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_geographic', :facetable), :label => 'Geographic', :sort => 'index', :limit => 10
    # these hidden facets are not defined for the facet panel UI, but for linked searches
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_neighborhood', :symbol), :label => 'Neighborhood', show: false
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_borough', :symbol), :label => 'Borough', show: false
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), :label => 'City', show: false
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_state', :symbol), :label => 'State', show: false
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_country', :symbol), :label => 'Country', show: false
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_repo_short', :symbol), :label => 'Library Location', :show => false

    default_facet_configuration(config, geo: true)

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field ActiveFedora::SolrService.solr_name('primary_name', :displayable), label: 'Name', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), label: 'Format'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), label: 'Collection Name', helper_method: :display_composite_archival_context
    config.add_index_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), label: 'Abstract', helper_method: :expandable_past_250
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_name', :displayable, type: :string), label: 'Name', tombstone_display: true, if: false


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_name', :displayable), label: 'Name', link_to_search: ActiveFedora::SolrService.solr_name('lib_name', :facetable), helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), label: 'Title'
    config.add_show_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), label: 'Abstract', helper_method: :expandable_past_400
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), label: 'Collection Name', helper_method: :display_collection_with_links
    config.add_show_field 'archival_context_json_ss', label: 'Archival Context', helper_method: :display_archival_context, if: :has_archival_context?
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_all_subjects', :displayable), label: 'Subjects'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), label: 'Format'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_genre', :symbol), label: 'Genre'
    config.add_show_field 'origin_info_date_created_ssm(0)', label: 'Origin Information', separator_options: COMMA_DELIMITED, accessor: :unpublished_origin_information, unless: :has_publisher?
    config.add_show_field 'origin_info_date_created_ssm(1)', label: 'Publication Information', separator_options: COMMA_DELIMITED, accessor: :published_origin_information, if: :has_publisher?
    config.add_show_field ActiveFedora::SolrService.solr_name('physical_description_extent', :displayable, type: :string), label: 'Physical Description', helper_method: :append_digital_origin
    config.add_show_field 'dynamic_notes', pattern: /lib_.*_notes_ssm/, label: :notes_label, helper_method: :expandable_past_250, unless: :is_excepted_dynamic_field?, except: ['lib_acknowledgment_notes_ssm']
    config.add_show_field ActiveFedora::SolrService.solr_name('language_language_term_text', :symbol), label: 'Language'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_repo_full', :symbol, type: :string), label: 'Library Location', helper_method: :show_translated_repository_label
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_acknowledgment_notes', :displayable), label: 'Acknowledgments'
    config.add_show_field 'copyright_statement_ssi', label: 'Copyright Status', helper_method: :display_as_link_to_rightsstatements

    config.add_citation_field ActiveFedora::SolrService.solr_name('ezid_doi', :symbol), label: 'Persistent URL', show: false, helper_method: :display_doi_link

    # solr fields to be displayed in the geo/map panels
    #  facetable (link: true)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_neighborhood', :symbol), label: 'Neighborhood', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_borough', :symbol), label: 'Borough', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), label: 'City', link: true
    #  nonfacetable (link: false)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_street', :symbol), label: 'Address', link: false
    config.add_geo_field 'geo', label: 'Coordinates', link: false
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_geographic', :facetable, type: :string), label: 'Location', link: false

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

    configure_keyword_search_field(config)
    configure_title_search_field(config)
    configure_name_search_field(config)

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc', :label => 'relevance'
    config.add_sort_field 'title_si asc', :label => 'title'
    config.add_sort_field 'lib_start_date_year_itsi asc', :label => 'date (earliest to latest)'
    config.add_sort_field 'lib_start_date_year_itsi desc', :label => 'date (latest to earliest)'

    # Respond to CSV
    config.index.respond_to.csv = true

    default_component_configuration(config)
  end

end
