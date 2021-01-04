module Dcv::Configurators::BaseBlacklightConfigurator
  module Constants
    COMMA_DELIMITER     = ', '.freeze
    LINEBREAK_DELIMITER = '<br />'.freeze.html_safe
    SEMICOLON_DELIMITER = '; '.freeze
    COMMA_DELIMITED     = { words_connector: COMMA_DELIMITER,     two_words_connector: COMMA_DELIMITER,     last_word_connector: COMMA_DELIMITER }
    LINEBREAK_DELIMITED = { words_connector: LINEBREAK_DELIMITER, two_words_connector: LINEBREAK_DELIMITER, last_word_connector: LINEBREAK_DELIMITER }
    SEMICOLON_DELIMITED = { words_connector: SEMICOLON_DELIMITER, two_words_connector: SEMICOLON_DELIMITER, last_word_connector: SEMICOLON_DELIMITER }
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

  def default_index_configuration(config)
    config.http_method = :post
    config.fetch_many_document_params = { fl: '*' } # default deprecation circumvention from BL6
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
end
