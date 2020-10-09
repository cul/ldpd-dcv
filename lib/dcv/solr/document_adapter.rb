# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class Abstract
    def initialize(src)
    end

    def to_solr(doc = {})
      raise NotImplementedError if self.class == Abstract
      doc
    end
  end
  autoload :ModsXml, 'dcv/solr/document_adapter/mods_xml'
end