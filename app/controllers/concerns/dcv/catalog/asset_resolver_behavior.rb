module Dcv::Catalog::AssetResolverBehavior
  extend ActiveSupport::Concern

  included do
    helper_method :identifier_to_pid
  end

  def identifier_to_pid(identifier_to_convert)
    id = identifier_to_convert.dup # Don't want to modify the passed-in object because it might be used again outside of this method
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p = blacklight_config.default_document_solr_params
    p[:fq] = "dc_identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise 'error' if solr_response.docs.empty?
    if solr_response.docs.empty?
      # ba2213 thought this was a good interim until we can verify that all docs have DC:identifier set appropriately
      p[:fq] = "identifier_ssim:#{(id)}"
      solr_response = find(blacklight_config.document_solr_path, p)
    end
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
    return @document.id
  end

end
