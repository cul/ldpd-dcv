# -*- encoding : utf-8 -*-
module Dcv::Solr::DocumentAdapter
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora]
    def ActiveFedora obj
      if Dcv::Solr::DocumentAdapter::ActiveFedora.matches_any_cmodel?(obj, ['info:fedora/ldpd:GenericResource'])
        return Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource.new(obj)
      elsif Dcv::Solr::DocumentAdapter::ActiveFedora.matches_any_cmodel?(obj, ['info:fedora/ldpd:ContentAggregator'])
        return Dcv::Solr::DocumentAdapter::ActiveFedora::ContentAggregator.new(obj)
      elsif Dcv::Solr::DocumentAdapter::ActiveFedora.matches_any_cmodel?(obj, ['info:fedora/ldpd:Concept'])
        return Dcv::Solr::DocumentAdapter::ActiveFedora::Concept.new(obj)
      elsif Dcv::Solr::DocumentAdapter::ActiveFedora.matches_any_cmodel?(obj, ['info:fedora/ldpd:Collection'])
        return Dcv::Solr::DocumentAdapter::ActiveFedora::Collection.new(obj)
      else
        return Dcv::Solr::DocumentAdapter::ActiveFedora.new(obj)
      end
    end
  end

  class ActiveFedora < Dcv::Solr::DocumentAdapter::Abstract
    autoload :Collection, 'dcv/solr/document_adapter/active_fedora/collection'
    autoload :Concept, 'dcv/solr/document_adapter/active_fedora/concept'
    autoload :ContentAggregator, 'dcv/solr/document_adapter/active_fedora/content_aggregator'
    autoload :GenericResource, 'dcv/solr/document_adapter/active_fedora/generic_resource'

    MODS_NS = {'mods' => 'http://www.loc.gov/mods/v3'}.freeze

    include RepresentativeGenericResourceBehavior
    attr_accessor :obj

    # Initialize adapter object with active_fedora object
    # Largely drawn from legacy class Cul::Hydra::Models::Common
    # @param obj_or_pid [String|ActiveFedora::Base]
    def initialize(obj_or_pid)
      if obj_or_pid.class == ::ActiveFedora::Base
        @obj = obj_or_pid
      elsif obj_or_pid.is_a? ::ActiveFedora::Base
        @obj = ::ActiveFedora::Base.allocate.init_with_object(obj_or_pid.inner_object)
      elsif obj_or_pid.is_a? String
        @obj = ::ActiveFedora::Base.find(obj_or_pid, cast: false)
      else
        Rails.logger.warn("Dcv::Solr::DocumentAdapter::ActiveFedora initialized with unexpected argument: #{obj_or_pid}")
      end
    end

    # Create or update a solr document with fields drawn from @obj 
    # @param doc [Hash]
    # @return [Hash]
    def to_solr(solr_doc={}, opts={})
      solr_doc = obj.to_solr(solr_doc, opts)

      # add DC indexing
      Dcv::Solr::DocumentAdapter::DcXml.new(obj.datastreams['DC'].content).to_solr(solr_doc)
      # add MODS indexing
      if has_desc?
        Dcv::Solr::DocumentAdapter::ModsXml.new(obj.datastreams['descMetadata'].content).to_solr(solr_doc)
        solr_doc["descriptor_ssi"] = ["mods"]
      else
        solr_doc["descriptor_ssi"] = ["dublin core"]
      end
      # if no mods, pull some values from DC
      if (solr_doc["title_display_ssm"].blank?)
        if (solr_doc["dc_title_ssm"].present?)
          solr_doc["title_display_ssm"] = solr_doc["dc_title_ssm"]
        else
          solr_doc["title_display_ssm"] = solr_doc["dc_identifier_ssim"]&.reject { |dcid| dcid.eql? obj.id }
        end
        solr_doc["title_si"] = solr_doc["title_display_ssm"]&.first
      end
      if (solr_doc["identifier_ssim"].blank?)
          solr_doc["identifier_ssim"] = solr_doc["dc_identifier_ssim"]&.reject {|dcid| dcid.eql? obj.id}
      end

      if solr_doc["contributor_ssim"].present?
        if solr_doc["contributor_ssim"].is_a?(Array)
          solr_doc["contributor_first_si"] = solr_doc["contributor_ssim"].first
        else
          solr_doc["contributor_first_si"] = solr_doc["contributor_ssim"]
        end
      end

      solr_doc["format_ssi"] = [route_as]

      set_size_labels(solr_doc)

      solr_doc.each_pair do |key, value|
        if value.is_a? Array
          value.each {|v| v.strip! unless v.nil? }
        elsif value.is_a? String
          value.strip!
        end
      end

      solr_doc['structured_bsi'] = true if has_struct_metadata?

      get_representative_generic_resource&.tap { |rgr| solr_doc['representative_generic_resource_pid_ssi'] = rgr.pid }

      # Index URI form of pid to facilitate solr joins
      solr_doc['fedora_pid_uri_ssi'] = 'info:fedora/' + obj.pid if obj.pid.present?
      solr_doc['datastreams_ssim'] = obj.datastreams.keys.map {|k| k.to_s }.sort

      # add XACML indexing
      if has_access_control_metadata?
        Dcv::Solr::DocumentAdapter::XacmlXml.new(obj.datastreams['accessControlMetadata'].content).to_solr(solr_doc)
      end

      # add RELS-INT indexing
      if has_rels_int?
        rels_int.to_solr(solr_doc)
      end

      solr_doc['all_text_teim']&.uniq!

      solr_doc
    end

    def route_as
      'default'
    end

    def index_type_label
      'DEFAULT'
    end

    # set the index type label and any RI-based fields
    def set_size_labels(solr_doc={})
      solr_doc["index_type_label_ssi"] = [index_type_label]
    end

    # legacy behavior is more stringent than other ds methods
    def has_desc?
      if obj.datastreams['descMetadata']&.has_content?
        return Nokogiri::XML(obj.datastreams['descMetadata'].content).xpath('/mods:mods/mods:identifier', MODS_NS).first
      end
      false
    end

    def has_struct_metadata?
      return obj.datastreams['structMetadata']&.has_content?
    end

    def has_access_control_metadata?
      return obj.datastreams['accessControlMetadata']&.has_content?
    end

    def has_rels_int?
      return obj.datastreams['RELS-INT']&.has_content?
    end

    def rels_int
      content = obj.datastreams["RELS-INT"].content
      ds = obj.create_datastream(Cul::Hydra::Datastreams::RelsInt, "RELS-INT", controlGroup: 'X', blob: content)
      ds
    end

    def get_singular_relationship_value(predicate)
      get_relationship_values(predicate)&.first
    end

    def self.get_relationship_values(obj, predicate)
      properties = obj.relationships(predicate)
      return [] unless properties.present?
      return properties.map { |property| (property.kind_of? RDF::Literal) ? property.value : property }
    end

    def get_relationship_values(predicate)
      ActiveFedora.get_relationship_values(obj, predicate)
    end

    # determine whether an object asserts any of the specified cmodels
    # matches_any_cmodel?(obj, ["info:fedora/ldpd:GenericResource"])
    # @param [ActiveFedora::Base] obj
    # @param [Array<String>] cmodels
    def self.matches_any_cmodel?(obj, cmodels)
      assertions = get_relationship_values(obj, :has_model).map { |rdf_prop| rdf_prop.to_s }
      return (assertions & Array(cmodels)).present?
    end

    def matches_any_cmodel?(cmodels)
      ActiveFedora.matches_any_cmodel?(obj, cmodels)
    end

    def proxies
      if has_struct_metadata?
        content = obj.datastreams['structMetadata'].content
        ds = obj.create_datastream(Cul::Hydra::Datastreams::StructMetadata, 'structMetadata', controlGroup: 'X', blob: content)
        ds.proxies
      end
    end

    def index_proxies(params = {softCommit: true})
      if has_struct_metadata?
        conn = ::ActiveFedora::SolrService.instance.conn
        # delete by query proxyIn_ssi: internal_uri
        conn.delete_by_query("proxyIn_ssi:#{RSolr.solr_escape(obj.internal_uri())}")

        # reindex proxies
        proxy_docs = proxies.collect {|p| p.to_solr}
        conn.add(proxy_docs, params: params)
        proxy_docs
      else
        []
      end
    end

    # add relevant solr documents to index
    # @param [Hash] params
    #  RSolr params
    # @return [Array<Hash>] documents added to solr, beginning with indexed ActiveFedora object
    def update_index(params = {softCommit: true})
      solr_doc = to_solr()
      ::ActiveFedora::SolrService.add(solr_doc, params)
      [solr_doc].concat index_proxies(params)
    end
  end
end