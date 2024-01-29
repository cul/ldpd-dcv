class Dcv::Configurators::Restricted::IfpBlacklightConfigurator

  extend Dcv::Configurators::BaseBlacklightConfigurator

  def self.configure(config)

    config.show.route = { controller: 'restricted/ifp' }

    config.default_solr_params = {
      :fq => [
        'active_fedora_model_ssi:GenericResource', # Only include GenericResources in searches
        '-dc_type_sim:FileSystem' # Ignore FileSystem resources in searches
      ],
      :qt => 'search',
      :rows => 20,
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

    config.add_facet_field 'contributor_ssim', :label => 'Office', :limit => 10, :sort => 'index'
    config.add_facet_field 'dc_type_sim', :label => 'Resource Type', :limit => 10, :sort => 'index', :helper_method => :pcdm_file_genre_display
    # add a query facet for negating file published to the public site
    config.add_facet_field 'publisher_ssim', label: 'Site Access', query: {
        onsite_only: {
            label: 'Onsite Only',
            fq: "-publisher_ssim:\"info:fedora/cul:rfj6q573w6\""
        }
    }

    default_faceting_configuration(config)

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'title_display_ssm', :label => 'Title'
    config.add_index_field 'contributor_ssim', :label => 'Office'
    config.add_index_field 'original_name_ssim', :label => 'Folder Path', :helper_method => :dirname_prefixed_with_slash
    config.add_index_field 'publisher_ssim', :label => 'Onsite Only', :helper_method => :onsite_only

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'contributor_ssim', :label => 'Office'
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

    # Fulltext search configuration, used by main search pulldown.
    config.add_search_field 'fulltext_tesim' do |field|
      field.label = 'Fulltext'
      field.default = true
      field.solr_parameters = {
        :qf => ['original_name_tesim^10.0','fulltext_tesim^1.0'],
        :pf => ['original_name_tesim^100.0','fulltext_tesim^10.0']
      }
      configure_fulltext_highlighting(field)
    end

    #config.add_search_field 'search_title_info_search_title_teim' do |field|
    #  field.label = 'Title'
    #  field.solr_parameters = {
    #    :qf => ['title_teim'],
    #    :pf => ['title_teim']
    #  }
    #end
    #
    #config.add_search_field 'lib_name_teim' do |field|
    #  field.label = 'Name'
    #  field.solr_parameters = {
    #    :qf => ['lib_name_teim'],
    #    :pf => ['lib_name_teim']
    #  }
    #end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'
    config.add_sort_field 'contributor_first_si asc, title_si asc', :label => 'Office'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.index.thumbnail_method = :thumbnail_for_doc

    default_component_configuration(config)
  end

end
