class Dcv::Solr::DocumentAdapter::ActiveFedora
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora::Concept]
    def Concept obj
      Dcv::Solr::DocumentAdapter::ActiveFedora::Concept.new(obj)
    end
  end
  class Concept < Dcv::Solr::DocumentAdapter::ActiveFedora
    include Dcv::Solr::DocumentAdapter::ActiveFedora::GenericAggregatorBehavior

    def route_as
      'concept'
    end

    def abstract
      get_singular_relationship_value(:abstract)
    end

    # a human readable PREMIS restriction ('Onsite', etc.)
    # http://www.loc.gov/premis/rdf/v1#hasRestriction
    def restriction
      get_singular_relationship_value(:restriction)
    end

    # a human readable URI segment for this concept
    # http://www.bbc.co.uk/ontologies/coreconcepts/slug
    def slug
      get_singular_relationship_value(:slug)
    end

    # a URI property indicating the service endpoint associated with this concept
    # http://purl.org/dc/terms/source
    def source
      get_singular_relationship_value(:source)
    end

    # a short or abbreviated title
    # http://purl.org/ontology/bibo/shortTitle
    def short_title
      get_singular_relationship_value(:short_title)
    end

    def description
      candidate =
        obj.relationships(:description).select { |v| v.to_s.index(obj.internal_uri.to_s) == 0 }
      candidate = candidate.first
      candidate = candidate.to_s.split('/')[2]
      obj.datastreams[candidate].content.to_s unless candidate.blank?
    end

    def to_solr(solr_doc={}, opts={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc unless obj.is_a?(::ActiveFedora::Base) && matches_any_cmodel?(["info:fedora/ldpd:Concept"])

      solr_doc['active_fedora_model_ssi'] = 'Concept'
      description.tap do |description_value|
        if description_value
          solr_doc['description_text_ssm'] = Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(description_value).encode(Encoding::UTF_8)
        end
      end
      solr_doc
    end
  end
end
