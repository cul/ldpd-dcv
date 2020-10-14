class Dcv::Solr::DocumentAdapter::ActiveFedora
  module GenericAggregatorBehavior
    def to_solr(solr_doc={}, opts={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc unless obj.is_a?(::ActiveFedora::Base)  # There is no object. Return because there is nothing to process, otherwise NoMethodError will be raised by subsequent lines.
      solr_doc
    end

    def route_as
      "multipartitem"
    end

    def index_type_label
      type_label_for(nil)
    end

    def type_label_for(size=nil)
      if size == 0
        return "EMPTY"
      elsif size == 1
        return "SINGLE PART"
      else
        return "MULTIPART"
      end
    end

    # set the index type label and any RI-based fields
    # overridde
    def set_size_labels(solr_doc={})
      count = Cul::Hydra::RisearchMembers.get_direct_member_count(obj.pid)
      solr_doc["index_type_label_ssi"] = [type_label_for(count)]
      solr_doc["cul_number_of_members_isi"] = count
    end
  end
end
