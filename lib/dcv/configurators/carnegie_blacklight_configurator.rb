class Dcv::Configurators::CarnegieBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config, fulltext: true)

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

    config.add_facet_field 'lib_name_sim', **default_facet_config(label: 'Names')
    config.add_facet_field 'subject_topic_sim', **default_facet_config(label: 'Topics')
    config.add_facet_field 'role_interviewee_ssim', **default_facet_config(label: 'Oral Histories')
    config.add_facet_field 'lib_format_sim', **default_facet_config(label: 'Formats')
    config.add_facet_field 'subject_geographic_sim',**default_facet_config(label: 'Geographic')
    # these hidden facets are not defined for the facet panel UI, but for linked searches
    config.add_facet_field 'subject_hierarchical_geographic_neighborhood_ssim', **default_facet_config(label: 'Neighborhood', show: false)
    config.add_facet_field 'subject_hierarchical_geographic_borough_ssim', **default_facet_config(label: 'Borough', show: false)
    config.add_facet_field 'subject_hierarchical_geographic_city_ssim', **default_facet_config(label: 'City', show: false)
    config.add_facet_field 'subject_hierarchical_geographic_state_ssim', **default_facet_config(label: 'State', show: false)
    config.add_facet_field 'subject_hierarchical_geographic_country_ssim', **default_facet_config(label: 'Country', show: false)
    config.add_facet_field 'lib_repo_short_ssim', **default_facet_config(label: 'Library Location', show: false)

    default_faceting_configuration(config, geo: true)

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'title_display_ssm', :label => 'Title'
    config.add_index_field 'primary_name_ssm', label: 'Name', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_index_field 'lib_format_ssm', label: 'Format'
    config.add_index_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_index_field 'lib_collection_ssm', label: 'Collection Name', helper_method: :display_composite_archival_context
    config.add_index_field 'abstract_ssm', label: 'Abstract', helper_method: :expandable_past_250
    config.add_index_field 'lib_name_ssm', label: 'Name', grid_display: true, if: false


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'lib_name_ssm', label: 'Name', link_to_facet: 'lib_name_sim', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_show_field 'title_display_ssm', label: 'Title'
    config.add_show_field 'abstract_ssm', label: 'Abstract', helper_method: :expandable_past_400
    config.add_show_field 'lib_collection_ssm', label: 'Collection Name', helper_method: :display_collection_with_links
    config.add_show_field 'archival_context_json_ss', label: 'Archival Context', helper_method: :display_archival_context, if: :has_archival_context?
    config.add_show_field 'lib_all_subjects_ssm', label: 'Subjects'
    config.add_show_field 'lib_format_ssm', label: 'Format'
    config.add_show_field 'lib_genre_ssim', label: 'Genre'
    config.add_show_field key: 'unpublished_origin_information', field: 'origin_info_date_created_ssm', label: 'Origin Information', separator_options: COMMA_DELIMITED, accessor: :unpublished_origin_information, unless: :has_publisher?
    config.add_show_field key: 'published_origin_information', field: 'origin_info_date_created_ssm', label: 'Publication Information', separator_options: COMMA_DELIMITED, accessor: :published_origin_information, if: :has_publisher?
    config.add_show_field 'physical_description_extent_ssm', label: 'Physical Description', helper_method: :append_digital_origin
    config.add_show_field 'dynamic_notes', pattern: /lib_.*_notes_ssm/, label: :notes_label, helper_method: :expandable_past_250, unless: :is_excepted_dynamic_field?, except: ['lib_acknowledgment_notes_ssm']
    config.add_show_field 'language_language_term_text_ssim', label: 'Language'
    config.add_show_field 'lib_repo_full_ssim', label: 'Library Location', helper_method: :show_translated_repository_label
    config.add_show_field 'lib_acknowledgment_notes_ssm', label: 'Acknowledgments'
    config.add_show_field 'copyright_statement_ssi', label: 'Copyright Status', helper_method: :display_as_link_to_rightsstatements

    config.add_citation_field 'ezid_doi_ssim', label: 'Persistent URL', show: false, helper_method: :display_doi_link

    # solr fields to be displayed in the geo/map panels
    #  facetable (link: true)
    config.add_geo_field 'subject_hierarchical_geographic_neighborhood_ssim', label: 'Neighborhood', link: true
    config.add_geo_field 'subject_hierarchical_geographic_borough_ssim', label: 'Borough', link: true
    config.add_geo_field 'subject_hierarchical_geographic_city_ssim', label: 'City', link: true
    #  nonfacetable (link: false)
    config.add_geo_field 'subject_hierarchical_geographic_street_ssim', label: 'Address', link: false
    config.add_geo_field 'geo', label: 'Coordinates', link: false
    config.add_geo_field 'subject_geographic_sim', label: 'Location', link: false

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
    configure_fulltext_search_field(config, default: false) if fulltext

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc', :label => 'relevance'
    config.add_sort_field 'title_si asc', :label => 'title'
    config.add_sort_field 'lib_start_date_year_itsi asc', :label => 'date (earliest to latest)'
    config.add_sort_field 'lib_start_date_year_itsi desc', :label => 'date (latest to earliest)'

    # Respond to CSV
    # the Proc is run via instance_exec in controller
    config.index.respond_to.csv = Proc.new { stream_csv_response_for_search_results }

    default_component_configuration(config, disclaimer: Dcv::Alerts::Disclaimers::CarnegieComponent)
  end

end
