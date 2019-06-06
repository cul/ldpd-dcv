module Dcv::IframeHelperBehavior
  include Dcv::CdnHelper

  # look for archive.org locations, or identifiers, or local ids
  # to reference as embeddable iframe source
  # @param document [Hash] a Solr document
  # @return [String] iframe source URL or nil
  def iframe_url_for_document(document={})
    if archive_org_id = archive_org_id_for_document(document)
      return "https://archive.org/stream/#{archive_org_id}?ui=full&showNavbar=false"
    end
  end
end
