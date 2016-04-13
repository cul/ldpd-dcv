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
  
  def get_item_in_context_urls()
    @item_in_context_urls ||= aggregate_item_in_context_urls()
  end
  
  private
  
  # Aggregate item in context urls from this solr document and all direct member solr documents
  def aggregate_item_in_context_urls()
    urls = []
    urls += self['lib_item_in_context_url_ssm'] if self['lib_item_in_context_url_ssm'].present?
    
    search_response = Blacklight.solr.get 'select', :params => {
      :q  => '*:*',
      :fl => 'lib_item_in_context_url_ssm',
      :qt => 'search',
      :fq => [
        'cul_member_of_ssim:"info:fedora/' + self['id'] + '"',
      ],
      :rows => 999,
      :facet => false
    }
    
    search_response['response']['docs'].each do |doc|
      urls += doc['lib_item_in_context_url_ssm'] if doc['lib_item_in_context_url_ssm'].present?
    end
    
    urls
  end

end
