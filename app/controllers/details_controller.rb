class DetailsController < ApplicationController
  include Dcv::CatalogIncludes
  include Dcv::Sites::SearchableController
  extend Dcv::Configurators::BaseBlacklightConfigurator

  layout 'details'

  _prefixes << 'catalog' # haaaaaaack to not reproduce templates

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 20
    }
    config.search_state_fields.concat(DETAILS_PARAMS)
    config.per_page = [20,60,100]
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

    config.add_facet_fields_to_solr_request! # Required for facet queries

    config.add_facet_field 'lib_project_sim', :label => 'Project'
    config.add_facet_field 'lib_collection_sim', :label => 'Collection'
    config.add_facet_field 'lib_repo_short_ssim', :label => 'Library Location'
    config.add_facet_field 'lib_name_sim', :label => 'Name'
    config.add_facet_field 'lib_format_sim', :label => 'Format'
    #todo: date
    #todo: language
    config.add_facet_field 'format_ssi', :label => 'System Format'

    config.add_facet_field 'lc1_letter_sim', :label => 'Call Number'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.map { |key, config| config.field || config.key }
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_display_ssm', :label => 'Title'
    config.add_index_field 'lib_collection_ssm', :label => 'Collection'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_display_ssm', :label => 'Title'
    config.add_show_field 'identifier_ssim', :label => 'Identifier'
    config.add_show_field 'lib_format_ssm', :label => 'Format'
    config.add_show_field 'lib_name_ssm', :label => 'Name'
    config.add_show_field 'lib_collection_ssm', :label=>"Collection"

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
    config.add_search_field 'all_text_teim' do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => ['all_text_teim'],
        :pf => ['all_text_teim']
      }
    end

    config.add_search_field 'search_title_info_search_title_teim' do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qf => ['search_title_info_search_title_teim'],
        :pf => ['search_title_info_search_title_teim']
      }
    end

    config.add_search_field 'lib_name_teim' do |field|
      field.label = 'Name'
      field.solr_parameters = {
        :qf => ['lib_name_teim'],
        :pf => ['lib_name_teim']
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def show
    id = params[:id]
    @response, @document = fetch(params[:id])
  end

  def embed
    id = params[:id]
    @response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=ezid_doi_ssim v=$ezid_doi_ssim}"
    if can?(Ability::ACCESS_ASSET, @document)
      response.headers.delete 'X-Frame-Options'
    else
      render file: 'public/404.html', layout: false, status: 404
      return
    end
  end
end
