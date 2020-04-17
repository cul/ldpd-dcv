require "open-uri"

class IndexFedoraObjectJob
  DEFAULT_OPTS = { skip_resources: false, verbose_output: false, reraise: false, softcommit: true }

  @queue = Dcv::Queue::INDEX_FEDORA_OBJECT # This is the default queue for this job

  def self.perform(conditions, queue_time_string=Time.now.to_s)
	conditions = conditions.dup
	pid = conditions.delete('pid')
	subsite_keys = conditions.delete('subsite_keys')
	index_opts = conditions.map { |k,v| [k.to_sym, v] }.to_h
	index_opts = DEFAULT_OPTS.merge(index_opts)

	puts "Indexing #{pid} to #{subsite_keys.join(', ')} at #{queue_time_string}" if index_opts[:verbose_output]
	Cul::Hydra::Indexer.index_pid(pid, index_opts)
  end

end
