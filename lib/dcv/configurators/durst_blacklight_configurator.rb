class Dcv::Configurators::DurstBlacklightConfigurator

  def self.solr_name(*args)
    ActiveFedora::SolrService.solr_name(*args)
  end

  def self.configure(config)

    config.show.route = { controller: 'durst' }

    config.default_solr_params = {
      :fq => ['lib_project_short_ssim:"Durst"','-active_fedora_model_ssi:GenericResource'],
      :qt => 'search',
      :rows => 20
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

    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => 'Format', :limit => 10, :sort => 'count', :multiselect => true, :ex => 'lib_format-tag'
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_hierarchical_geographic_neighborhood', :symbol), :label => 'Neighborhood', :limit => 10, :sort => 'count'
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_hierarchical_geographic_borough', :symbol), :label => 'Borough', :limit => 10, :sort => 'count'
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_hierarchical_geographic_city', :symbol), :label => 'City', :limit => 10, :sort => 'count'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_name', :displayable, type: :string), :label => 'Name'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_published_string', :displayable, type: :string), :label => 'Published', :separator => '<br />'.html_safe

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => 'Title', :separator => '<br />'.html_safe.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('alternative_title', :displayable, type: :string), :label => 'Alternative Titles', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_name', :displayable), :label => 'Name', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('origin_info_edition', :displayable, type: :string), :label => 'Edition', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_published_string', :displayable, type: :string), :label => 'Published', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('physical_description_extent', :displayable, type: :string), :label => 'Physical Description', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_all_subjects', :displayable, type: :string), :label => 'Subjects', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('table_of_contents', :displayable, type: :string), :label => 'Contents', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('abstract', :displayable, type: :string), :label => 'Summary', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), :label => 'Format', :separator => '<br />'.html_safe
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_non_date_notes', :displayable, type: :string), :label => 'Notes', :separator => '<br />'.html_safe

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

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.index.thumbnail_method = :thumbnail_for_doc

  end

end
