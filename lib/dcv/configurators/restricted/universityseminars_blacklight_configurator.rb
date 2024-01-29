class Dcv::Configurators::Restricted::UniversityseminarsBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'restricted/universityseminars' }

    config.default_solr_params = {
      :fq => [
        '-active_fedora_model_ssi:GenericResource', # Only include GenericResources in searches
        '-dc_type_sim:FileSystem' # Ignore FileSystem resources in searches
      ],
      :qt => 'search',
      :rows => 20
    }

    default_paging_configuration(config)
    # default solr field configuration for search results/index and show views
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

    config.add_facet_field 'primary_name_sim', **default_facet_config(label: "Seminar Numbers")
    config.add_facet_field 'subject_topic_sim', **default_facet_config(label: "Seminar Titles")
    config.add_facet_field 'lib_format_sim', **default_facet_config(label: "Document Types")
    config.add_facet_field 'language_language_term_text_ssim', **default_facet_config(label: "Languages")

    default_faceting_configuration(config)


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'title_display_ssm', :label => 'Title'
    config.add_index_field 'primary_name_ssm', :label => 'Seminar Number'
    config.add_index_field 'location_sublocation_ssm', :label => 'Department'
    config.add_index_field 'location_shelf_locator_ssm', :label => 'Shelf Location'
    config.add_index_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_index_field 'lib_item_in_context_url_ssm', :label => 'Item in Context', :helper_method => :link_to_url_value
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_display_ssm', :label => 'Title'
    config.add_show_field 'alternative_title_ssm', :label => 'Alternative Titles'
    config.add_show_field 'primary_name_ssm', :label => 'Seminar Number', :link_to_search => 'primary_name_sim'
    config.add_show_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_show_field 'lib_non_date_notes_ssm', :label => 'Note'
    config.add_show_field 'lib_date_notes_ssm', :label => 'Date Note'
    config.add_show_field 'location_sublocation_ssm', :label => 'Department'
    config.add_show_field 'location_shelf_locator_ssm', :label => 'Shelf Location'
    config.add_show_field 'physical_description_extent_ssm', :label => 'Physical Description'
    config.add_show_field 'lib_all_subjects_ssm', :label => 'Subjects'
    config.add_show_field 'abstract_ssm', :label => 'Summary'
    config.add_show_field 'table_of_contents_ssm', :label => 'Contents'
    config.add_show_field 'lib_part_ssm', :label => 'Part'
    config.add_show_field 'lib_publisher_ssm', :label => 'Publisher'
    config.add_show_field 'origin_info_place_ssm', :label => 'Place'
    config.add_show_field 'origin_info_edition_ssm', :label => 'Edition'
    configure_file_show_fields(config)

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

    configure_fulltext_search_field(config)

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'

    default_component_configuration(config)
  end

end
