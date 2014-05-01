class CollectionsController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior

  layout :collection_layout

  parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates

  def collection_layout
    puts CUSTOM_COLLECTIONS.inspect
    puts params.inspect
    layout = CUSTOM_COLLECTIONS.fetch(self.controller_name, DEFAULT_COLLECTION)['layout']
    "#{layout}.html.erb"
  end

  def solr_search_params(user_params = params || {})
    solr_params = super
    add_collection_fq(solr_params, user_params)
    solr_params
  end

  def add_collection_fq(solr_parameters, user_params)
    collection_id = CUSTOM_COLLECTIONS.fetch(self.controller_name, DEFAULT_COLLECTION)['collection_id']
    collection_id.strip!
    user_params = {f: {
      #cul_member_of_ssim: "info:fedora/#{collection_id}".gsub(/:/,'\:')
      lib_format_sim: "photographs"
      }}
      puts "user_params: #{user_params.inspect}"
    add_facet_fq_to_solr(solr_parameters, user_params)
    puts solr_parameters.inspect
  end

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]


  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 10
    }

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
    config.add_facet_field solr_name('lib_collection', :facetable), :label => 'Collection'
    config.add_facet_field solr_name('lib_repo', :facetable), :label => 'Repository'
    config.add_facet_field solr_name('lib_format', :facetable), :label => 'Format'
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
    config.add_index_field solr_name('title_vern', :stored_searchable, type: :string), :label => 'Title'
    config.add_index_field solr_name('author', :stored_searchable, type: :string), :label => 'Author'
    config.add_index_field solr_name('author_vern', :stored_searchable, type: :string), :label => 'Author'
    config.add_index_field solr_name('lib_format', :displayable), :label => 'Format'
    config.add_index_field solr_name('lib_repo', :displayable), :label => 'Repository'
    config.add_index_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_index_field solr_name('published', :stored_searchable, type: :string), :label => 'Published'
    config.add_index_field solr_name('published_vern', :stored_searchable, type: :string), :label => 'Published'
    config.add_index_field solr_name('lc_callnum', :stored_searchable, type: :string), :label => 'Call number'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name('title_display', :stored_searchable, type: :string), :label => 'Title'
    config.add_show_field solr_name('title_vern', :stored_searchable, type: :string), :label => 'Title'
    config.add_show_field solr_name('subtitle', :stored_searchable, type: :string), :label => 'Subtitle'
    config.add_show_field solr_name('subtitle_vern', :stored_searchable, type: :string), :label => 'Subtitle'
    config.add_show_field solr_name('author', :stored_searchable, type: :string), :label => 'Author'
    config.add_show_field solr_name('author_vern', :stored_searchable, type: :string), :label => 'Author'
    config.add_show_field solr_name('format', :symbol), :label => 'Format'
    config.add_show_field solr_name('url_fulltext_tsim', :stored_searchable, type: :string), :label => 'URL'
    config.add_show_field solr_name('url_suppl_tsim', :stored_searchable, type: :string), :label => 'More Information'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_show_field solr_name('published', :stored_searchable, type: :string), :label => 'Published'
    config.add_show_field solr_name('published_vern', :stored_searchable, type: :string), :label => 'Published'
    config.add_show_field solr_name('lc_callnum', :stored_searchable, type: :string), :label => 'Call number'
    config.add_show_field solr_name('isbn', :stored_searchable, type: :string), :label => 'ISBN'

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

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', :label => 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_local_parameters = {
        :qf => '$author_qf',
        :pf => '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, pub_date_dtsi desc, title_si asc', :label => 'relevance'
    config.add_sort_field 'pub_date_dtsi desc, title_si asc', :label => 'year'
    config.add_sort_field 'author_tesi asc, title_si asc', :label => 'author'
    config.add_sort_field 'title_si asc, pub_date_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.show.route = {controller: :current}
  end

end