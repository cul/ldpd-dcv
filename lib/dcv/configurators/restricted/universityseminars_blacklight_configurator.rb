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

    config.add_facet_field ActiveFedora::SolrService.solr_name('primary_name', :facetable), { 
      :label => "Seminar Numbers", :limit => 10, :sort => "index"}
    config.add_facet_field "subject_topic_sim", :label => "Seminar Titles", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => "Document Types", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('language_language_term_text', :symbol), :label => "Languages", :limit => 10, :sort => "index"

    default_facet_configuration(config)


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field ActiveFedora::SolrService.solr_name('primary_name', :displayable, type: :string), :label => 'Seminar Number'
    config.add_index_field ActiveFedora::SolrService.solr_name('location_sublocation', :displayable, type: :string), :label => 'Department'
    config.add_index_field ActiveFedora::SolrService.solr_name('location_shelf_locator', :displayable, type: :string), :label => 'Shelf Location'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_item_in_context_url', :displayable, type: :string), :label => 'Item in Context', :helper_method => :link_to_url_value
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_show_field ActiveFedora::SolrService.solr_name('alternative_title', :displayable, type: :string), :label => 'Alternative Titles'
    config.add_show_field ActiveFedora::SolrService.solr_name('primary_name', :displayable), :label => 'Seminar Number', :link_to_search => ActiveFedora::SolrService.solr_name('primary_name', :facetable)
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_non_date_notes', :displayable, type: :string), :label => 'Note'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_date_notes', :displayable, type: :string), :label => 'Date Note'
    config.add_show_field ActiveFedora::SolrService.solr_name('location_sublocation', :displayable, type: :string), :label => 'Department'
    config.add_show_field ActiveFedora::SolrService.solr_name('location_shelf_locator', :displayable, type: :string), :label => 'Shelf Location'
    config.add_show_field ActiveFedora::SolrService.solr_name('physical_description_extent', :displayable, type: :string), :label => 'Physical Description'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_all_subjects', :displayable, type: :string), :label => 'Subjects'
    config.add_show_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), :label => 'Summary'
    config.add_show_field ActiveFedora::SolrService.solr_name('table_of_contents', :displayable, type: :string), :label => 'Contents'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_part', :displayable, type: :string), :label => 'Part'
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_publisher', :displayable, type: :string), :label => 'Publisher'
    config.add_show_field ActiveFedora::SolrService.solr_name('origin_info_place', :displayable, type: :string), :label => 'Place'
    config.add_show_field ActiveFedora::SolrService.solr_name('origin_info_edition', :displayable, type: :string), :label => 'Edition'
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
  end

end
