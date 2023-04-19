module Dcv::Configurators::BaseBlacklightConfigurator
  module Constants
    COMMA_DELIMITER     = ', '.freeze
    LINEBREAK_DELIMITER = '<br />'.freeze.html_safe
    SEMICOLON_DELIMITER = '; '.freeze
    COMMA_DELIMITED     = { words_connector: COMMA_DELIMITER,     two_words_connector: COMMA_DELIMITER,     last_word_connector: COMMA_DELIMITER }
    LINEBREAK_DELIMITED = { words_connector: LINEBREAK_DELIMITER, two_words_connector: LINEBREAK_DELIMITER, last_word_connector: LINEBREAK_DELIMITER }
    SEMICOLON_DELIMITED = { words_connector: SEMICOLON_DELIMITER, two_words_connector: SEMICOLON_DELIMITER, last_word_connector: SEMICOLON_DELIMITER }
    # BL needs to know what params to permit for searches beyond configured filter fields
    BROWSE_LIST_PARAMS = [:list_id]
    CORE_PARAMS = [:id]
    DETAILS_PARAMS = [:initial_page, :layout, :title]
    DATE_RANGE_PARAMS = [:end_year, :start_year]
    COORD_PARAMS = [:lat, :long]
    SUBSITE_PARAMS = [:slug, :site_slug]
    FILESYSTEM_PARAMS = [:proxy_id, :return_to_filesystem]
    READING_ROOM_PARAMS = [:repository_id]
  end

  def self.extended(extendor)
    extendor.include Constants
  end

  def solr_name(*args)
    ActiveFedora::SolrService.solr_name(*args)
  end

  def notes_label_proc
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

  def default_default_solr_params(config)
    config.default_solr_params = {
      defType: 'edismax',
      fq: [
        'object_state_ssi:A', # Active items only
        '-active_fedora_model_ssi:GenericResource', # Do not include GenericResources in searches
      ],
      qt: 'search',
      rows: 20,
      mm: 1
    }
  end

  def default_index_configuration(config)
    config.search_state_fields.concat(Constants::CORE_PARAMS).concat(Constants::DATE_RANGE_PARAMS)
                              .concat(Constants::COORD_PARAMS).concat(Constants::SUBSITE_PARAMS)
                              .concat(Constants::FILESYSTEM_PARAMS).concat(Constants::READING_ROOM_PARAMS)
                              .concat(Constants::BROWSE_LIST_PARAMS)
    config.http_method = :post
    config.fetch_many_document_params = { fl: '*' } # default deprecation circumvention from BL6
    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
    config.index.display_type_field = :active_fedora_model_ssi
    config.index.thumbnail_method = :thumbnail_for_doc
    config.index.document_presenter_class = Dcv::IndexPresenter
    config.index.grid_size = 4
  end

  def default_show_configuration(config)
    config.show.route = { controller: :current }
    config.show.display_type_field = :active_fedora_model_ssi
    config.show.document_presenter_class = Dcv::ShowPresenter
  end

  def default_paging_configuration(config)
    config.default_per_page = 20
    config.per_page = [20,60,100]
    config.max_per_page = 100
  end

  def default_facet_configuration(config, opts = {})
    config.add_facet_fields_to_solr_request! # Required for facet queries
    if opts[:geo]
      config.add_facet_field 'has_geo_bsi', :label => 'Geo Data Flag', show: false, limit: 2
    end

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params['facet.field'] = config.facet_fields.keys
    config.default_solr_params['facet.limit'] = 60
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params['facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys
  end

  def default_component_configuration(config, opts = {})
    config.index.constraints_component = opts.fetch(:constraints, Dcv::ConstraintsComponent)
    config.index.document_component = opts.fetch(:document, Dcv::DocumentComponent)
    config.index.facet_group_component = opts.fetch(:facet_group, Dcv::Response::FacetGroupComponent)
    config.index.search_bar_component = opts.fetch(:search_bar, Dcv::SearchBar::DefaultComponent)
    config.show.disclaimer_component = opts.fetch(:disclaimer, Dcv::Alerts::Disclaimers::DefaultComponent)
    config.home ||= Blacklight::Configuration::ViewConfig.new
    config.home.featured_items_component = Dcv::Gallery::MosaicComponent
  end

  # All Text search configuration, used by main search pulldown.
  def configure_keyword_search_field(config, opts = {})
    field_name = ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)
    return false if config.search_fields[field_name]
    config.add_search_field field_name do |field|
      field.label = opts.fetch(:label, 'All Fields')
      field.default = opts.fetch(:default, true)
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)]
      }
    end
  end

  # Title search configuration, used by main search pulldown.
  def configure_title_search_field(config, opts = {})
    field_name = ActiveFedora::SolrService.solr_name('search_title_info_search_title', :searchable, type: :text)
    return false if config.search_fields[field_name]
    config.add_search_field field_name do |field|
      field.label = opts.fetch(:label, 'Title')
      field.default = opts.fetch(:default, true)
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)]
      }
    end
  end

  # Identifier search configuration, used by main search pulldown.
  def configure_identifier_search_field(config, opts = {})
    field_name = ActiveFedora::SolrService.solr_name('identifier', :symbol)
    return false if config.search_fields[field_name]
    config.add_search_field field_name do |field|
      field.label = opts.fetch(:label, 'Document ID')
      field.default = opts.fetch(:default, true)
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('identifier', :symbol)],
        :pf => [ActiveFedora::SolrService.solr_name('identifier', :symbol)]
      }
    end
  end

  # Name search configuration, used by main search pulldown.
  def configure_name_search_field(config, opts = {})
    config.add_search_field ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text) do |field|
      field.label = opts.fetch(:label, 'Name')
      field.default = opts.fetch(:default, true)
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)]
      }
    end
  end

  # Full Text search configuration, used by main search pulldown.
  def configure_fulltext_search_field(config, opts = {})
    config.add_search_field ActiveFedora::SolrService.solr_name('fulltext', :stored_searchable, type: :text) do |field|
      field.label = opts.fetch(:label, 'Full Text')
      field.default = opts.fetch(:default, true)
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('fulltext', :stored_searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('fulltext', :stored_searchable, type: :text)]
      }
      if opts.fetch(:highlight, true)
        configure_fulltext_highlighting(field)
      end
    end
  end

  def configure_fulltext_highlighting(search_field)
    search_field.solr_parameters ||= {}
    hl_params = {}
    hl_params[:hl] = true
    hl_params[:'hl.fragsize'] = 300
    hl_params[:'hl.usePhraseHighlighter'] = true
    hl_params[:ps] = 0
    hl_params[:qs] = 0
    hl_params[:'hl.maxAnalyzedChars'] = 1000000
    hl_params[:'hl.simple.pre'] = Dcv::HighlightedSnippetHelper::SNIPPET_HTML_WRAPPER_PRE
    hl_params[:'hl.simple.post'] = Dcv::HighlightedSnippetHelper::SNIPPET_HTML_WRAPPER_POST
    search_field.solr_parameters.reverse_merge! hl_params
  end

  def configure_file_show_fields(config, opts = {})
    config.add_show_field 'original_name_ssim', label: 'Folder Path', helper_method: :dirname_prefixed_with_slash, if: :show_file_fields?
    config.add_show_field 'identifier_ssim', label: 'Identifier', if: :show_file_fields?
    config.add_show_field 'extent_ssim', label: 'Size', helper_method: :show_extent_in_bytes, if: :show_file_fields?
    config.add_show_field 'dc_format_ssm', label: 'MIME Type', helper_method: :mime_type_field_value, if: :show_file_fields?
  end
end
