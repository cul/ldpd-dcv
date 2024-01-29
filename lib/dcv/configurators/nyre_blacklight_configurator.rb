class Dcv::Configurators::NyreBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'nyre' }

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

    config.add_facet_field 'role_architect_ssim', **default_facet_config(label: 'Architect')
    config.add_facet_field 'role_owner_agent_ssim', **default_facet_config(label: 'Owner/Agent')
    config.add_facet_field 'subject_hierarchical_geographic_neighborhood_ssim', **default_facet_config(label: 'Neighborhood', sort: 'count')
    config.add_facet_field 'subject_hierarchical_geographic_borough_ssim', **default_facet_config(label: 'Borough', sort: 'count')
    config.add_facet_field 'subject_hierarchical_geographic_city_ssim', **default_facet_config(label: 'City', sort: 'count')
    config.add_facet_field 'classification_other_ssim', **default_facet_config(label: 'Call Number', show: false)

    default_faceting_configuration(config, geo: true)

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'title_display_ssm', :label => 'Title'
    config.add_index_field 'lib_repo_long_ssim', :label => 'Library Location'
    config.add_index_field 'role_architect_ssim', :label => 'Architect'
    config.add_index_field 'role_owner_agent_ssim', :label => 'Owner/Agent'
    config.add_index_field 'location_sublocation_ssm', :label => 'Department'
    config.add_index_field 'location_shelf_locator_ssm', :label => 'Shelf Location'
    config.add_index_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_index_field 'abstract_ssm', :label => 'Summary', :helper_method => :truncate_text_to_250
    config.add_index_field 'cul_number_of_members_isi', :label => 'Number of Images'
    config.add_index_field 'classification_other_ssim', :label => 'Call Number', :link_to_search => 'classification_other_ssim'
    config.add_index_field 'lib_name_ssm', label: 'Name', tombstone_display: true, if: false

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_display_ssm', :label => 'Title'
    config.add_show_field 'lib_repo_full_ssim', :label => 'Library Location', :helper_method => :show_field_repository_to_facet_link
    config.add_show_field 'role_architect_ssim', :label => 'Architect', :link_to_search => 'role_architect_ssim'
    config.add_show_field 'role_owner_agent_ssim', :label => 'Owner/Agent', :link_to_search => 'role_owner_agent_ssim'
    config.add_show_field 'classification_other_ssim', :label => 'Call Number', :link_to_search => 'classification_other_ssim'
    config.add_show_field 'lib_format_ssm', :label => 'Format'
    config.add_show_field 'subject_hierarchical_geographic_region_ssim', :label => 'Region'
    config.add_show_field 'subject_hierarchical_geographic_city_ssim', :label => 'City'
    config.add_show_field 'lib_project_full_ssim', :label => 'Digital Project'
    config.add_show_field 'lib_collection_ssm', :label => 'Collection'
    config.add_show_field 'lib_date_textual_ssm', :label => 'Date'
    config.add_show_field 'lib_non_date_notes_ssm', :label => 'Note'
    config.add_show_field 'location_shelf_locator_ssm', :label => 'Shelf Location'
    config.add_show_field 'physical_description_extent_ssm', :label => 'Physical Description'
    config.add_show_field 'identifier_ssim', :label => 'Identifier'
    config.add_show_field 'ezid_doi_ssim', :label => 'DOI'
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

    config.add_search_field 'role_architect_ssim' do |field|
      field.label = 'Architect'
      field.solr_parameters = {
        :qf => ['role_architect_ssim'],
        :pf => ['role_architect_ssim']
      }
    end

    config.add_search_field 'role_owner_agent_ssim' do |field|
      field.label = 'Owner/Agent'
      field.solr_parameters = {
        :qf => ['role_owner_agent_ssim'],
        :pf => ['role_owner_agent_ssim']
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc', :label => 'relevance'
    config.add_sort_field 'title_si asc', :label => 'title'
    config.add_sort_field 'lib_start_date_year_itsi asc', :label => 'date (earliest to latest)'
    config.add_sort_field 'lib_start_date_year_itsi desc', :label => 'date (latest to earliest)'

    default_component_configuration(config)
  end

end
