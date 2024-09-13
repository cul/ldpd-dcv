require 'csv'

namespace :dcv do
	namespace :dois do
		task assign: :environment do
			CSV.open(ENV['csv'], 'rb', headers: true) do |csv|
				csv.each do |row|
					fedora_object = ActiveFedora::Base.find(row['pid'])
					predicate = :ezid_doi
					fedora_object.clear_relationship(predicate)
					Array(row['doi']).each { |value| fedora_object.add_relationship(predicate, "doi:#{value}") }
					fedora_object.datastreams["RELS-EXT"].content_will_change!
					fedora_object.save
					IndexFedoraObjectJob.perform({'pid' => row['pid'], 'subsite_keys' => ['ifp'], 'reraise' => true})
				end
			end
		end
	end
end