shared_context "site fixtures for features", shared_context: :metadata do
  before do
    # import from solr data, since db will have been torn down
    SolrDocument.each_site_document do |document|
      site_import = Dcv::Sites::Import::Solr.new(document)
      next unless site_import.exists?
      site_import.run
    end
  end
end
