require 'csv'

namespace :dcv do

  namespace :sites do
    task import: :environment do
      site_import = Dcv::Sites::Import::Directory.new(ENV['directory'])
      if site_import.exists?
        site_import.run
      else
        puts "No site export at #{ENV['directory']}"
      end
    end
    task seed_from_solr: :environment do
      SolrDocument.each_site_document do |document|
        site_import = Dcv::Sites::Import::Solr.new(document)
        next unless site_import.exists?
        site_import.run
      end
    end
  end
end