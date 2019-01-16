module Dcv::IframeHelperBehavior

  # look for archive.org locations, or identifiers, or local ids
  # to reference as embeddable iframe source
  # @param document [Hash] a Solr document
  # @return [String] iframe source URL or nil
  def iframe_url_for_document(document={})
    urls = document['lib_non_item_in_context_url_ssm'] || []
    archive_org_location = urls.detect { |url| url =~ /\/archive\.org\// }
    if archive_org_location
      archive_org_id = archive_org_location.split('/')[-1]
    end
    archive_org_id ||= document["archive_org_identifier_ssi"]
    if archive_org_id
      return "https://archive.org/stream/#{archive_org_id}?ui=embed"
    end
  end
end
