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
    def self.concatenate_fulltext(solr_doc, obj)
      solr_doc["fulltext_tesim"] ||= []
      unless obj.datastreams["fulltext"].nil?
        solr_doc["fulltext_tesim"].concat(solr_doc["title_display_ssm"]) unless solr_doc["title_display_ssm"].nil? or solr_doc["title_display_ssm"].length == 0
        utf8able = Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(obj.datastreams["fulltext"].content)
        solr_doc["fulltext_tesim"] << utf8able.encode(Encoding::UTF_8)
      end
      solr_doc
    end

    def route_as
      'resource'
    end
    def index_type_label
      'FILE ASSET'
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

      Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource.concatenate_fulltext(solr_doc, obj)

      obj.relationships(:original_name).each do |original_name|
        solr_doc["original_name_tesim"] ||= []
        original_name = original_name.object.to_s.split('/').join(' ')
        solr_doc["original_name_tesim"] << original_name.strip
      end

      # the structured field is explicitly false rather than absent in the legacy class
      # the legacy class also keys it with a symbol
      solr_doc[:structured_bsi] = 'false'

      solr_doc
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
      # we have to 'manually' query the graph because rels_int doesn't support subject pattern matching
      rels_int = self.rels_int
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
      return nil
    end
  end
end
