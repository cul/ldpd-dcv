class Dcv::Configurators::DcvBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    configure_default_solr_params(config)

    default_paging_configuration(config)

    # solr field configuration for search results/index views
    default_index_configuration(config)

    default_show_configuration(config)

    configure_facet_fields(config)

    default_faceting_configuration(config)

    configure_index_fields(config)

    configure_show_fields(config)

    configure_citation_fields(config)

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

    configure_sort_fields(config)

    default_component_configuration(config, search_bar: Dcv::SearchBar::CatalogComponent)
  end

  def self.configure_default_solr_params(config)
    default_default_solr_params(config).merge!({
      fq: [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:(ContentAggregator OR Concept)'
      ],
      bq: 'active_fedora_model_ssi:Concept^100', # Boost Concepts before all other results
      qt: 'search'
    })
  end

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
  def self.configure_facet_fields(config)
    config.add_facet_field 'lib_name_sim', **default_facet_config(label: 'Name')
    config.add_facet_field 'lib_format_sim', **default_facet_config(label: 'Format/Genre', sort: 'count')
    config.add_facet_field 'language_language_term_text_ssim', **default_facet_config(label: 'Language', sort: 'count')
    config.add_facet_field 'lib_collection_sim', **default_facet_config(label: 'Library Collection', sort: 'count')
    config.add_facet_field 'lib_repo_short_ssim', **default_facet_config(label: 'Library Location')
    config.add_facet_field 'lib_project_short_ssim', **default_facet_config(label: 'Digital Project', sort: 'count', show: false)
    config.add_facet_field 'project_key', **default_facet_config(field: 'project_key_ssim', label: 'Digital Project', sort: 'count', show: false)
  end

  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  def self.configure_sort_fields(config)
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'
  end

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display
  def self.configure_index_fields(config)
    config.add_index_field 'primary_name_ssm', label: 'Name', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_index_field 'rel_other_project_ssim', :label => 'Project'
    config.add_index_field 'lib_repo_long_ssim', :label => 'Library Location'
    config.add_index_field 'location_sublocation_ssm', :label => 'Department'
    config.add_index_field 'lib_collection_ssm', label: 'Collection Name', helper_method: :display_composite_archival_context
    config.add_index_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_index_field 'lib_item_in_context_url_ssm', :label => 'Item in Context', :helper_method => :link_to_url_value
    config.add_index_field 'lib_name_ssm', label: 'Name', tombstone_display: true, if: false
  end

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display
  def self.configure_show_fields(config)
    configure_file_show_fields(config)
    config.add_show_field 'lib_name_ssm', label: 'Name', link_to_search: 'lib_name_sim', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_show_field 'rel_other_project_ssim', :label => 'Project'
    config.add_show_field 'title_display_ssm', label: 'Title'
    config.add_show_field 'alternative_title_ssm', :label => 'Other Titles'
    config.add_show_field 'abstract_ssm', label: 'Abstract', helper_method: :expandable_past_400, iiif: false
    config.add_show_field 'lib_collection_ssm', label: 'Collection Name', helper_method: :display_collection_with_links, iiif: false
    config.add_show_field 'archival_context_json_ss', label: 'Archival Context', helper_method: :display_archival_context, if: :has_archival_context?
    config.add_show_field 'location_shelf_locator_ssm', label: 'Shelf Location', unless: :has_archival_context?, archival_context_field: 'archival_context_json_ss'
    config.add_show_field 'accession_number_ssm', label: 'Accession Number'
    config.add_show_field 'lib_all_subjects_ssm', label: 'Subjects'
    config.add_show_field 'lib_format_ssm', label: 'Format'
    config.add_show_field 'lib_culture_genre_ssim', label: 'Culture'
    config.add_show_field 'lib_genre_ssim', label: 'Genre'
    config.add_show_field 'origin_info_edition_ssm', :label => 'Edition'
    config.add_show_field 'origin_info_place_for_display_ssm', label: 'Origin Information', separator_options: COMMA_DELIMITED, unless: :has_publisher?
    config.add_show_field 'origin_info_date_created_ssm', label: 'Publication Information', separator_options: COMMA_DELIMITED, accessor: :published_origin_information, if: :has_publisher?
    config.add_show_field 'lib_date_textual_ssm', :label => 'Date', :helper_method => :show_date_field
    config.add_show_field 'physical_description_extent_ssm', :label => 'Physical Description'
    config.add_show_field 'dynamic_notes', pattern: /lib_.*_notes_ssm/, label: :notes_label, helper_method: :expandable_past_250, unless: :is_excepted_dynamic_field?, except: ['lib_acknowledgment_notes_ssm'], join: false
    config.add_show_field 'language_language_term_text_ssim', :label => 'Language', :link_to_search => 'language_language_term_text_ssim'
    config.add_show_field 'table_of_contents_ssm', :label => 'Contents'
    config.add_show_field 'lib_repo_short_ssim', label: 'Library Location', helper_method: :show_field_repository_to_facet_link, link_to_search: true, iiif: false
    config.add_show_field 'location_sublocation_ssm', :label => 'Department'
    config.add_show_field 'clio_ssim', label: 'Catalog Record', helper_method: :render_link_to_clio, join: false
    config.add_show_field 'lib_part_ssm', :label => 'Part'
    config.add_show_field 'lib_project_full_ssim', label: 'Digital Project', helper_method: :show_field_project_to_facet_link, link_to_search: :project_key, if: :show_digital_project?, unless_fields: :project_key_ssim
    config.add_show_field 'project_key_ssim', label: 'Digital Project', helper_method: :show_field_project_to_facet_link, link_to_search: :project_key, if: :show_digital_project?
    config.add_show_field 'other_sites_data', :label => 'Also In', :helper_method => :show_link_to_other_site_home
    # Note: Do NOT show the access_condition field. See DCV-465 for explanation.
    #config.add_show_field 'access_condition_ssim', :label => 'Rights'
    config.add_show_field 'lib_acknowledgment_notes_ssm', label: 'Acknowledgments'
    config.add_show_field 'copyright_statement_ssi', label: 'Copyright Status', helper_method: :display_as_link_to_rightsstatements
  end

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display
  #   citation fields are a custom field group in the DLC
  def self.configure_citation_fields(config)
    config.add_citation_field 'ezid_doi_ssim', label: 'Persistent URL', show: false, helper_method: :display_doi_link
    config.add_citation_field 'location_url_json_ss', label: 'Related URLs', if: :has_related_urls?, helper_method: :display_related_urls, join: false
  end
end
