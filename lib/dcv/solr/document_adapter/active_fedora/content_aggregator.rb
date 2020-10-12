class Dcv::Solr::DocumentAdapter::ActiveFedora
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora::ContentAggregator]
    def ContentAggregator obj
      Dcv::Solr::DocumentAdapter::ActiveFedora::ContentAggregator.new(obj)
    end
  end
  class ContentAggregator < Dcv::Solr::DocumentAdapter::ActiveFedora
    include Dcv::Solr::DocumentAdapter::ActiveFedora::GenericAggregatorBehavior

    def to_solr(solr_doc={}, opts={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc unless obj.is_a?(::ActiveFedora::Base) && test_cmodels(["info:fedora/ldpd:ContentAggregator"])

      solr_doc['active_fedora_model_ssi'] = 'ContentAggregator'
      Cul::Hydra::RisearchMembers.get_direct_members_with_datastream_pids(obj.pid, 'fulltext').each do |pid|
        member = ActiveFedora::Base.find(obj.pid)
        if member.is_a? GenericResource
          Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource.concatenate_fulltext(solr_doc, member)
        end
      end
      solr_doc
    end
  end
end
