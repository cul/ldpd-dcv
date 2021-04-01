module Dcv::Utils::UrlUtils

  # Return the preferred bytestream name:
  # 1. content if the original name matches a pattern in keep_originals
  # 2. access if available
  # 3. content by default
  # @param doc [Hash] SolrDocument
  # @param keep_originals [Array<Regexp>] name patterns to defer to original for
  # @return [String] preferred bytestream name
  def self.preferred_content_bytestream(doc, *keep_originals)
    doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
    if doc.is_a?(SolrDocument)
      originals = doc['original_name_ssim'] || doc[:original_name_ssim] || []
      datastreams = doc['datastreams_ssim'] || doc[:datastreams_ssim] || ['content']
      if originals.detect {|o| keep_originals.detect {|k| k.match(o) } }
        return (['service','content'] & datastreams.map(&:to_s)).first
      end
      return (['access','service','content'] & datastreams.map(&:to_s)).first
    end
    return nil
  end
end
