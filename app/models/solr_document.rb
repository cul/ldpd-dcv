require 'blacklight/document'
# -*- encoding : utf-8 -*-
class SolrDocument

  ACCESS_CONTROL_FIELDS = [
    'access_control_affiliations_ssim',
    'access_control_locations_ssim',
    'access_control_embargo_dtsi',
    'access_control_permissions_bsi',
    'access_control_levels_ssim'
  ]

  TITLE_FIELDS = ['title_ssm', 'title_display_ssm', 'dc_title_ssm']

  include Blacklight::Solr::Document
  include SolrDocument::FieldSemantics
  include SolrDocument::PublicationInfo
  include SolrDocument::Snippets

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # Item in context url for this solr document. Might return nil if this doc has no item in context url.
  def item_in_context_url
    self['lib_item_in_context_url_ssm']&.first
  end

  def site_result?
    self['dc_type_ssm'].present? && self['dc_type_ssm'].include?('Publish Target')
  end

  def solr_url_hash(opts = {})
    candidates = JSON.parse(self.fetch(:location_url_json_ss, "[]"))
    exclude = opts.fetch(:exclude, {})
    candidates.select do |c|
      !c.detect { |k,v| exclude[k] == v }
    end
  end

  def has_persistent_url?
    key = site_result? ? :source_ssim : :ezid_doi_ssim
    self[key].present?
  end

  def persistent_url
    if has_persistent_url?
      if site_result?
        clean_resolver(self[:source_ssim].present? ? Array(self[:source_ssim]).first : nil)
      else
        "https://doi.org/#{self[:ezid_doi_ssim][0].to_s.sub(/^doi\:/,'')}"
      end
    end
  end

  def doi_identifier
    if self[:ezid_doi_ssim].present?
      return self[:ezid_doi_ssim][0].to_s.sub(/^doi\:/,'') || self[:ezid_doi_ssim][0].to_s
    end
  end

  def archive_org_identifier
    urls = self[:lib_non_item_in_context_url_ssm] || []
    archive_org_location = urls.detect { |url| url =~ /\/archive\.org\// }
    if archive_org_location
      return archive_org_location.split('/')[-1]
    end
    self[:archive_org_identifier_ssi]
  end

  def schema_image_identifier
    schema_image = Array(fetch('schema_image_ssim', [])).first
    # non-site behavior
    schema_image = self['representative_generic_resource_pid_ssi'] if schema_image.blank?
    if schema_image.present?
      schema_image.split('/')[-1]
    else
      nil
    end
  end

  # Scrub permanent links from catalog data to use modern resolver syntax
  # @param perma_link [String] the original link
  # @return [String] link with cgi version of resolver replaced with modern version
  def clean_resolver(link_src)
    if link_src
      link_uri = URI(link_src)
      if link_uri.path == "/cgi-bin/cul/resolve" && link_uri.host == "www.columbia.edu"
        return "https://library.columbia.edu/resolve/#{link_uri.query}"
      end
    end
    link_src
  end

  def slug
    if self[:restriction_ssim].present?
      Array(self[:slug_ssim]).compact.map { |val| "restricted/#{val}"  }.first
    else
      Array(self[:slug_ssim]).compact.first
    end
  end

  def unqualified_slug
    Array(self[:slug_ssim]).compact.first
  end

  def has_restriction?
    self[:restriction_ssim].present?
  end

  def title
    title_val = (TITLE_FIELDS.inject(nil) { |memo, field| memo || self[field]&.first }) || id
    title_val.to_s.strip
  end

  # merge behaviors that presume HashWithIndifferentAccess targets
  def merge_source!(target)
    @_source = _source.merge(target).with_indifferent_access.freeze
  end

  def merge_source(target)
    self.class.new(_source).merge_source!(target)
  end

  def source_delete(key)
    prev_val = self[key]
    @_source = @_source.except(key).with_indifferent_access.freeze
    prev_val
  end

  # merge behaviors that presume SolrDocument targets
  def merge_document!(solr_document)
    merge_source!(solr_document._source)
  end

  def merge_document(solr_document)
    self.class.new(_source).merge_document!(solr_document)
  end

  def self.each_site_document(index = Blacklight.default_index, fl = '*', &block)
    rsolr = index.connection
    solr_params = {
    qt: 'search',
    rows: 10000,
    fl: fl,
    fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
    facet: false
    }
    res = rsolr.send_and_receive('select', params: solr_params.to_hash, method: :get)
    solr_response = Blacklight::Solr::Response.new(res, solr_params, solr_document_model: self)
    solr_response['response']['docs'].each {|doc| block.yield new(doc)}
  end
end
