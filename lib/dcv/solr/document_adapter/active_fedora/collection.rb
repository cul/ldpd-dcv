class Dcv::Solr::DocumentAdapter::ActiveFedora
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora::Collection]
    def Collection obj
      Dcv::Solr::DocumentAdapter::ActiveFedora::Collection.new(obj)
    end
  end
  class Collection < Dcv::Solr::DocumentAdapter::ActiveFedora
    include Dcv::Solr::DocumentAdapter::ActiveFedora::GenericAggregatorBehavior

    def to_solr(solr_doc={}, opts={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc unless obj.is_a?(::ActiveFedora::Base) && test_cmodels(["info:fedora/ldpd:Collection"])

      solr_doc['active_fedora_model_ssi'] = 'Collection'
      solr_doc
    end
  end
end
