# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class Abstract
    def initialize(src)
    end

    def to_solr(doc = {})
      raise NotImplementedError if self.class == Abstract
      doc
    end

    def normal(value)
      normal!(value.clone)
    end

    def normal!(value)
      value.gsub!(/\s+/,' ')
      value.strip!
      value
    end

    def textable(value)
      Array(value).map {|v| normal(v)}
    end
  end
  autoload :DcXml, 'dcv/solr/document_adapter/dc_xml'
  autoload :ModsXml, 'dcv/solr/document_adapter/mods_xml'
end