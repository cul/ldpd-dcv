# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Catalog::SearchParamsLogicBehavior
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::DateRangeSelectorBehavior
  include Dcv::Catalog::RandomItemBehavior
  include Dcv::Catalog::AlternateHomePages # Temporary, for demos

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]

  layout 'dcv'

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 20
    }

    config.per_page = [20,60,100]
    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
    config.index.display_type_field = solr_name('has_model', :symbol)

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

    config.add_facet_field solr_name('lib_project', :facetable), :label => 'Digital Project', :limit => 10
    config.add_facet_field solr_name('lib_collection', :facetable), :label => 'Collection', :limit => 10
    config.add_facet_field solr_name('lib_repo', :facetable), :label => 'Repository', :sort => 'index', :limit => 10
    config.add_facet_field solr_name('lib_name', :facetable), :label => 'Name', :limit => 10
    config.add_facet_field solr_name('lib_format', :facetable), :label => 'Format', :limit => 10
    config.add_facet_field solr_name('language_language_term_text', :facetable), :label => 'Language', :limit => 10
    #todo: date
    #todo: language
    config.add_facet_field 'format_ssi', :label => 'System Format'

    config.add_facet_field solr_name('lc1_letter', :facetable), :label => 'Call Number'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_index_field solr_name('lib_collection', :displayable, type: :string), :label => 'Collection'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name('title_display', :displayable, type: :string), :label => 'Title'
    config.add_show_field solr_name('identifier', :symbol), :label => 'Identifier'
    config.add_show_field solr_name('lib_format', :displayable), :label => 'Format'
    config.add_show_field solr_name('lib_name', :displayable), :label => 'Name'
    config.add_show_field solr_name('lib_collection', :displayable), :label=>"Collection"

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
    config.add_search_field solr_name('all_text', :searchable, type: :text) do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => ['all_text_teim'],
        :pf => ['all_text_teim']
      }
    end

    config.add_search_field solr_name('search_title_info_search_title', :searchable, type: :text) do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qf => [solr_name('search_title_info_search_title', :searchable, type: :text)],
        :pf => [solr_name('search_title_info_search_title', :searchable, type: :text)]
      }
    end

    config.add_search_field solr_name('lib_name', :searchable, type: :text) do |field|
      field.label = 'Name'
      field.solr_parameters = {
        :qf => [solr_name('lib_name', :searchable, type: :text)],
        :pf => [solr_name('lib_name', :searchable, type: :text)]
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

    config.index.thumbnail_method = :thumbnail_for_doc
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def resolve
    get_solr_response_for_app_id
    action = params.delete(:resolve)
    action.sub!(/s$/,'')
    method_name = action + '_url'
    url = send method_name.to_sym, @document[:id]
    redirect_to url
  end

  def home
    if Rails.env == 'development' || ! Rails.cache.exist?(BROWSE_LISTS_KEY)
      refresh_browse_lists_cache
    end
    @browse_lists = Rails.cache.read(BROWSE_LISTS_KEY)

    number_of_items_to_show = 8

    # Use list of repositories from previous query and select a random one
    repositories_and_counts = @browse_lists['lib_repo_sim']['value_pairs'].dup
    if repositories_and_counts.length > number_of_items_to_show
      selected_repository_keys = repositories_and_counts.keys.shuffle[0, number_of_items_to_show]
    else
      selected_repository_keys = repositories_and_counts.keys
    end

    rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']

    list_of_ids_to_retrieve = []

    selected_repository_keys.each do |repository_key|
      repository_to_query = repository_key
      expected_response_count = repositories_and_counts[repository_key]

      # Do solr query for each repository
      response = rsolr.get 'select', :params => {
        :q  => '*:*',
        :fl => 'id',
        :qt => 'search',
        :fq => [
          'lib_repo_sim:"' + repository_to_query + '"', # Need quotes because values can contain spaces
          '-active_fedora_model_ssi:GenericResource' # Not retrieving file assets
        ],
        :rows => 1,
        :facet => false,
        :start => Random.new.rand(0..expected_response_count-1)
      }

      docs = response['response']['docs']

      if docs.length > 0
        # Append single document id to list_of_ids_to_retrieve
        list_of_ids_to_retrieve << docs[0]['id']
        puts 'list_of_ids_to_retrieve: ' + list_of_ids_to_retrieve.inspect
      end
    end

    (@response, @document_list) = get_search_results({:per_page => number_of_items_to_show}, {:fq => 'id:(' + list_of_ids_to_retrieve.map{|id| id.gsub(':', '\:')}.join(' OR ') + ')'})
  end
end
