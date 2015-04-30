module Dcv::Queue

  INDEX_FEDORA_OBJECT = :index_fedora_object

  QUEUES_IN_DESCENDING_PRIORITY_ORDER = [INDEX_FEDORA_OBJECT]
  
  def self.index_object(conditions)	
    if DCV_CONFIG['queue_long_jobs']
			Resque.enqueue(IndexFedoraObjectJob, conditions)
		else
			IndexFedoraObjectJob.perform(conditions)
		end
  end

end
