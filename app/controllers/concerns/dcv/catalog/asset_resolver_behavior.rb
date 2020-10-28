module Dcv::Catalog::AssetResolverBehavior
  extend ActiveSupport::Concern

  included do
    helper_method :identifier_to_pid
  end

  def identifier_to_pid(identifier_to_convert)
    @converted_ids ||= {}
    @converted_ids[identifier_to_convert] ||= begin
      convertible_id = identifier_to_convert.dup # Don't want to modify the passed-in object because it might be used again outside of this method
      convertible_id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
      convertible_id.gsub!(':','\:')
      convertible_id.gsub!('/','\/')

      p = blacklight_config.default_document_solr_params.merge(fq: "dc_identifier_ssim:\"#{convertible_id}\"")
      solr_response, resolved_list = search_results(p) { |b| b.merge(p) }
      solr_response = 
      if resolved_list.empty?
        # ba2213 thought this was a good interim until we can verify that all docs have DC:identifier set appropriately
        p[:fq] = "identifier_ssim:\"#{convertible_id}\""
        solr_response, resolved_list = search_results(p) { |b| b.merge(p) }
      end
      if resolved_list.empty?
        nil
      else
        resolved_list.first.id
      end
    end
  end
end
