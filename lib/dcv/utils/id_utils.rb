module Dcv::Utils::IdUtils
  def self.archive_org_id_for_document(document)
    document = SolrDocument.new(document) unless document.is_a? SolrDocument
    document.archive_org_identifier
  end
end
