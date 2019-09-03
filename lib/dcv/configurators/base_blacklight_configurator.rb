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
end
