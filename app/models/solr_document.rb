# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)
  
  # Aggregate item in context urls for this solr doc and its children, returning a hash that maps pids to item in context urls
  def self_and_child_pids_to_item_in_context_urls
    return @self_and_child_pids_to_item_in_context_urls ||= begin
      pids_to_urls = {}
      pids_to_urls[self['id']] = item_in_context_url if item_in_context_url.present?
      
      pids_to_urls.merge(child_pids_to_item_in_context_urls)
    end
  end
  
  # Item in context url for this solr document. Might return nil if this doc has no item in context url.
  def item_in_context_url
    self['lib_item_in_context_url_ssm'].present? ? self['lib_item_in_context_url_ssm'].first : nil
  end
  
  def child_pids_to_item_in_context_urls
    return @child_pids_to_item_in_context_urls ||= begin
      pids_to_urls = {}
      search_response = Blacklight.solr.get 'select', :params => {
        :q  => '*:*',
        :fl => 'id,lib_item_in_context_url_ssm',
        :qt => 'search',
        :fq => [
          'cul_member_of_ssim:"info:fedora/' + self['id'] + '"'
        ],
        :rows => 999,
        :facet => false
      }
      search_response['response']['docs'].each do |doc|
        pids_to_urls[doc['id']] = doc['lib_item_in_context_url_ssm'].first if doc['lib_item_in_context_url_ssm'].present?
      end
      pids_to_urls
    end
  end

  def site_result?
    self['dc_type_ssm'].present? && self['dc_type_ssm'].include?('Publish Target')
  end
end
