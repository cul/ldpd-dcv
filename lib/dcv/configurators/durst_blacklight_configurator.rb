class Dcv::Configurators::DurstBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'durst' }

    default_default_solr_params(config)

    config.per_page = [24,60,108]
    config.default_per_page = 24
    config.max_per_page = 108

    # solr field configuration for search results/index views
    default_index_configuration(config)
    config.search_state_fields << :durst_favorites
    config.index.grid_size = 6

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

    config.add_facet_field 'lib_format_sim', **default_facet_config(label: 'Format', sort: 'count',
      multiselect: true, ex: 'lib_format-tag', cul_custom_value_transforms: [:capitalize],
      item_component: Dcv::FacetItemComponent)
    config.add_facet_field 'subject_hierarchical_geographic_neighborhood_ssim', **default_facet_config(label: 'Neighborhood', sort: 'count')
    config.add_facet_field 'subject_hierarchical_geographic_borough_ssim', **default_facet_config(label: 'Borough', sort: 'count')
    config.add_facet_field 'subject_hierarchical_geographic_city_ssim', **default_facet_config(label: 'City', sort: 'count')
    #Hidden facets
    config.add_facet_field 'durst_subjects_sim', **default_facet_config(label: 'Durst Subject', show: false)

    default_faceting_configuration(config, geo: true)

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'primary_name_ssm', label: 'Name', grid_display: true
    config.add_index_field 'lib_date_textual_ssm', :label => 'Published', accessor: :published_origin_information, if: :has_publication_info?
    config.add_index_field 'lib_format_ssm', label: 'Format', grid_display: true
    config.add_index_field 'lib_non_item_in_context_url_ssm', label: 'Online', link_label: 'click here for full-text', helper_method: :render_link_to_external_resource, join: false
    config.add_index_field 'clio_ssim', label: 'Catalog Record', link_label: 'check availability', helper_method: :render_link_to_clio, join: false

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # Note: We have a more complex layout that doesn't work with the basic, easy blacklight show fields, so there's no point to filling these out
    config.add_show_field 'title_display_ssm', :label => 'Title', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'alternative_title_ssm', :label => 'Alternative Titles', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_name_ssm', :label => 'Name', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_date_textual_ssm', :label => 'Published', accessor: :published_origin_information, if: :has_publication_info?
    config.add_show_field 'origin_info_edition_ssm', :label => 'Edition', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'physical_description_extent_ssm', :label => 'Physical Description', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_all_subjects_ssm', :label => 'Subjects', separator_options: LINEBREAK_DELIMITED, :helper_method => :split_complex_subject_into_links
    config.add_show_field 'table_of_contents_ssm', :label => 'Contents', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'abstract_ssm', :label => 'Summary', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_format_ssm', :label => 'Format', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_non_date_notes_ssm', :label => 'Notes', separator_options: LINEBREAK_DELIMITED
    config.add_show_field 'lib_sublocation_ssm', label: 'Location', helper_method: :display_sublocation_information, if: :match_filter?, filter: 'lib_format_ssm:postcards'
    config.add_show_field 'lib_non_item_in_context_url_ssm', label: 'Online', link_label: 'click here for full-text', helper_method: :render_link_to_external_resource, join: false
    config.add_show_field 'clio_ssim', label: 'Catalog Record', link_label: 'check availability', helper_method: :render_link_to_clio, join: false

    # solr fields to be displayed in the geo/map panels
    #  facetable (link: true)
    config.add_geo_field 'subject_hierarchical_geographic_neighborhood_ssim', label: 'Neighborhood', link: true
    config.add_geo_field 'subject_hierarchical_geographic_borough_ssim', label: 'Borough', link: true
    config.add_geo_field 'subject_hierarchical_geographic_city_ssim', label: 'City', link: true
    #  nonfacetable (link: false)
    config.add_geo_field 'subject_hierarchical_geographic_street_ssim', label: 'Address', link: false
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

    configure_keyword_search_field(config)
    configure_title_search_field(config)
    configure_name_search_field(config)


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'

    default_component_configuration(config, search_bar: Dcv::SearchBar::DurstComponent)
  end

end
