require "open-uri"

class IndexFedoraObjectJob

  @queue = Dcv::Queue::INDEX_FEDORA_OBJECT # This is the default queue for this job

  def self.perform(conditions, queue_time_string=Time.now.to_s)
		pid = conditions['pid']
		subsite_keys = conditions['subsite_keys']
    softcommit = conditions['softcommit'] || true

		puts "Indexing #{pid} to #{subsite_keys.join(', ')} at #{queue_time_string}"
		#obj = ActiveFedora::Base.find(pid)
		#obj.update_index
		Cul::Hydra::Indexer.index_pid(pid, false, false, softcommit)
  end

end
