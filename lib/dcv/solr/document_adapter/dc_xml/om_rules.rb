class Dcv::Solr::DocumentAdapter::DcXml
  module OmRules
    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc if dc.nil?  # There is no dc.  Return because there is nothing to process, otherwise NoMethodError will be raised by subsequent lines.

      solr_doc["all_text_teim"] ||= []
      #t.root(path: "dc", :namespace_prefix=>"oai_dc", schema:"http://www.openarchives.org/OAI/2.0/oai_dc.xsd",
      #       "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
      #       "xmlns:dc"=>"http://purl.org/dc/elements/1.1/")
      #t.dc_contributor(path: "contributor", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:contributor", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_contributor_ssm"] = element_values
        solr_doc["dc_contributor_teim"] = textable(element_values)
      end
      #t.dc_coverage(path: "coverage", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:coverage", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_coverage_ssm"] = element_values
        solr_doc["dc_coverage_teim"] = textable(element_values)
      end
      #t.dc_creator(path: "creator", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:creator", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_creator_ssm"] = element_values
        solr_doc["dc_creator_teim"] = textable(element_values)
      end
      #t.dc_date(path: "date", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:date", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_date_ssm"] = element_values
        solr_doc["dc_date_teim"] = textable(element_values)
      end
      #t.dc_description(path: "description", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:description", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_description_ssm"] = element_values
        solr_doc["dc_description_teim"] = textable(element_values)
      end
      #t.dc_format(path: "format", namespace_prefix: "dc", index_as: [:displayable, :facetable])
      element_values = dc.xpath("dc:format", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_format_ssm"] = element_values
        solr_doc["dc_format_sim"] = element_values
      end
      #t.dc_identifier(path: "identifier", namespace_prefix: "dc", type: :string, index_as: [:symbol])
      element_values = dc.xpath("dc:identifier", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_identifier_ssim"] = element_values
      end
      #t.dc_language(path: "language", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:language", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_language_ssm"] = element_values
        solr_doc["dc_language_teim"] = textable(element_values)
      end
      #t.dc_publisher(path: "publisher", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:publisher", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_publisher_ssm"] = element_values
        solr_doc["dc_publisher_teim"] = textable(element_values)
      end
      #t.dc_relation(path: "relation", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:relation", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_relation_ssm"] = element_values
        solr_doc["dc_relation_teim"] = textable(element_values)
        clio_values = element_values.select { |val| val =~ /clio:/ }.map { |val| val.split(':')[-1] }
        solr_doc["clio_ssim"] = clio_values if clio_values.present?
      end
      #t.dc_rights(path: "rights", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:rights", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_rights_ssm"] = element_values
        solr_doc["dc_rights_teim"] = textable(element_values)
      end
      #t.dc_source(path: "source", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:source", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_source_ssm"] = element_values
        solr_doc["dc_source_teim"] = textable(element_values)
      end
      #t.dc_subject(path: "subject", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:subject", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_subject_ssm"] = element_values
        solr_doc["dc_subject_teim"] = textable(element_values)
      end
      #t.dc_title(path: "title", namespace_prefix: "dc", index_as: [:displayable, :searchable])
      element_values = dc.xpath("dc:title", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_title_ssm"] = element_values
        solr_doc["dc_title_teim"] = textable(element_values)
      end
      #t.dc_type(path: "type", namespace_prefix: "dc", index_as: [:displayable, :facetable])
      element_values = dc.xpath("dc:type", DC_NS).map(&:text)
      if element_values.present?
        solr_doc["dc_type_ssm"] = element_values
        solr_doc["dc_type_sim"] = element_values
      end
      solr_doc
    end
  end
end