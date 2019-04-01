class Dcv::Configurators::CarnegieBlacklightConfigurator

  def self.solr_name(*args)
    ActiveFedora::SolrService.solr_name(*args)
  end

  def self.notes_label_proc
    Proc.new do |doc, opts|
      field = opts[:field]
      type = field.split('_')[1..-3].join(' ').capitalize
      if type.eql?('Untyped')
        "Note"
      else
        "Note (#{type})"
      end
    end
  end

  def self.configure(config)

    config.show.route = { controller: 'carnegie' }

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
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
    config.index.display_type_field = ActiveFedora::SolrService.solr_name('has_model', :symbol)

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

    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_name', :facetable), :label => 'Names', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_topic', :facetable), :label => 'Topics', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('role_interviewee', :symbol), :label => 'Oral Histories', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => 'Formats', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('subject_geographic', :facetable), :label => 'Geographic', :sort => 'index', :limit => 10
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_repo_short', :symbol), :label => 'Library Location', :show => false
    config.add_facet_field 'format_ssi', :label => 'System Format', :sort => 'count' if ['development', 'test', 'dcv_dev', 'dcv_private_dev'].include?(Rails.env)

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field ActiveFedora::SolrService.solr_name('primary_name', :displayable), label: 'Name', separator: '; ', helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), label: 'Format', separator: '; '
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), label: 'Collection Name', separator: '; ', helper_method: :display_composite_archival_context
    config.add_index_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), label: 'Abstract', helper_method: :expandable_past_250

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_name', :displayable), label: 'Name', separator: '; ', link_to_search: ActiveFedora::SolrService.solr_name('lib_name', :facetable), helper_method: :display_non_copyright_names_with_roles, if: :has_non_copyright_names?
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), label: 'Title', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), label: 'Abstract', helper_method: :expandable_past_400
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), label: 'Collection Name', separator: '; ', helper_method: :display_collection_with_links
    config.add_show_field 'archival_context_json_ss', label: 'Archival Context', separator: '; ', helper_method: :display_archival_context, if: :has_archival_context?
    config.add_show_field ActiveFedora::SolrService.solr_name('location_shelf_locator', :displayable, type: :string), label: 'Shelf Location of Original', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('subject_topic', :facetable), label: 'Subjects', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), label: 'Format', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_genre', :symbol), label: 'Genre', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('origin_info_date_created', :displayable), label: 'Origin Information', separator: ', ', helper_method: :display_origin_info, unless: :is_dateless_origin_info?
    config.add_show_field ActiveFedora::SolrService.solr_name('origin_info_place', :displayable), label: 'Origin Information', separator: ', ', helper_method: :display_dateless_origin_info, if: :is_dateless_origin_info?
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_publisher', :displayable), label: 'Publication Information', separator: ', ', helper_method: :display_publication_info
    config.add_show_field ActiveFedora::SolrService.solr_name('physical_description_extent', :displayable, type: :string), label: 'Physical Description of Original', separator: '; ', helper_method: :append_digital_origin
    config.add_show_field 'dynamic_notes', pattern: /lib_.*_notes_ssm/, label: :notes_label, separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_non_date_notes', :displayable, type: :string), label: 'Note', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('language_language_term_text', :symbol), label: 'Language', separator: '; '
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_repo_full', :symbol, type: :string), label: 'Library Location', separator: '; ', helper_method: :show_repository_to_web_link
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_project_full', :symbol), label: 'Digital Project', separator: '; ', helper_method: :display_as_link_to_home

    config.add_citation_field 'archival_context_json_ss', label: 'Catalog Record for Collection', separator: '; ', helper_method: :display_collection_bib_links, if: :has_collection_bib_links?
    config.add_citation_field ActiveFedora::SolrService.solr_name('ezid_doi', :symbol), label: 'Persistent URL', separator: '; ', show: false, helper_method: :display_doi_link

    # solr fields to be displayed in the geo/map panels
    #  facetable (link: true)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_neighborhood', :symbol), label: 'Neighborhood', separator: '; ', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_borough', :symbol), label: 'Borough', separator: '; ', link: true
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_city', :symbol), label: 'City', separator: '; ', link: true
    #  nonfacetable (link: false)
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_street', :symbol), label: 'Address', separator: '; ', link: false
    config.add_geo_field 'geo', label: 'Coordinates', link: false
    config.add_geo_field ActiveFedora::SolrService.solr_name('subject_geographic', :facetable, type: :string), label: 'Location', separator: '; ', link: false

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

    config.index.thumbnail_method = :thumbnail_for_doc

    # Respond to CSV
    config.index.respond_to.csv = true

  end

end
