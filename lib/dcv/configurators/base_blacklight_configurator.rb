module Dcv::Configurators::BaseBlacklightConfigurator

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
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
    config.index.display_type_field = :active_fedora_model_ssi
    config.index.thumbnail_method = :thumbnail_for_doc
    config.index.document_presenter_class = Dcv::IndexPresenter
  end

  def default_show_configuration(config)
    config.show.route = { controller: :current }
    config.show.display_type_field = :active_fedora_model_ssi
    config.show.document_presenter_class = Dcv::ShowPresenter
  end
end
