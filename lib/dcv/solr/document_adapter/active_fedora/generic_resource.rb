class Dcv::Solr::DocumentAdapter::ActiveFedora
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource]
    def GenericResource obj
      Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource.new(obj)
    end
  end
  class GenericResource < Dcv::Solr::DocumentAdapter::ActiveFedora
    def initialize(obj)
      super
      @iiif_adapter = Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource::IiifData.new(obj)
    end

    def concatenate_fulltext(solr_doc)
      (solr_doc["fulltext_tesim"] ||= []).concat fulltext_values(solr_doc["title_display_ssm"])
      solr_doc
    end

    def route_as
      'resource'
    end
    def index_type_label
      'FILE ASSET'
    end

    def original_name_text
      obj.relationships(:original_name).map do |original_name|
        original_name = original_name.object.to_s.split('/').join(' ').strip
      end
    end

    def fulltext_values(title_values = nil)
      _fulltext_values = []
      unless obj.datastreams["fulltext"].nil?
        _fulltext_values.concat(Array(title_values)) unless title_values.blank?
        utf8able = Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(obj.datastreams["fulltext"].content)
        _fulltext_values << utf8able.encode(Encoding::UTF_8)
      end
      _fulltext_values
    end

    def to_solr(solr_doc={}, opts={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc unless obj.is_a?(::ActiveFedora::Base) && matches_any_cmodel?(["info:fedora/ldpd:GenericResource"])

      solr_doc['active_fedora_model_ssi'] = 'GenericResource'

      unless solr_doc["extent_ssim"].present? || obj.datastreams["content"].nil?
        if obj.datastreams["content"].dsSize.to_i > 0
          solr_doc["extent_ssim"] = [obj.datastreams["content"].dsSize]
        else
          repo = ActiveFedora::Base.connection_for_pid(obj.pid)
          ds_parms = {pid: obj.pid, dsid: "content", method: :head}
          repo.datastream_dissemination(ds_parms) do |res|
            solr_doc["extent_ssim"] = res['Content-Length']
          end
        end
      end

      if (service_ds = service_datastream)
        solr_doc['service_dslocation_ss'] = service_ds.dsLocation
      end

      concatenate_fulltext(solr_doc)

      solr_doc["original_name_tesim"] = original_name_text

      # the structured field is explicitly false rather than absent in the legacy class
      solr_doc['structured_bsi'] = false

      @iiif_adapter.to_solr(solr_doc)
    end

    def has_struct_metadata?
      false
    end

    # @return the dsid of a zooming content or nil
    def zooming_dsid
      content = obj.datastreams['content']
      return nil unless content
      zr = rels_int.relationships(content, :foaf_zooming)
      if (zr && zr.first)
        return zr.first.present? ? zr.first.object.to_s.split('/')[-1] : nil
      else
        nil
      end
    end

    def service_datastream
      return nil unless has_rels_int?
      # we have to 'manually' query the graph because rels_int doesn't support subject pattern matching
      args = [:s, rels_int.to_predicate(:format_of), RDF::URI.new("#{obj.internal_uri}/content")]
      query = RDF::Query.new { |q| q << args }
      candidates = query.execute(rels_int.graph).map(&:to_hash).map do |hash|
        hash[:s]
      end
      args = [:s, rels_int.to_predicate(:rdf_type), RDF::URI.new("http://pcdm.org/use#ServiceFile")]
      query = RDF::Query.new { |q| q << args }
      candidates &= query.execute(rels_int.graph).map(&:to_hash).map do |hash|
        hash[:s]
      end
      candidate_dsid = candidates.first && candidates.first.to_s.split('/')[-1]
      return obj.datastreams[candidate_dsid] if obj.datastreams.keys.include? candidate_dsid
    end
  end
end
