namespace :util do
  namespace :usem do
  	task :update_publish_target => :environment do
			
			old_publish_target_pid = 'project:usem'
			new_publish_target_pid = 'cul:s7h44j0zxt'
			
			start_time = Time.now
			pids = Cul::Hydra::RisearchMembers.get_publish_target_member_pids(old_publish_target_pid, true)
			total = pids.length
			puts "Found #{total} publish target members."
			counter = 0

			pids.each do |pid|
				counter += 1
				
				begin
					obj = ActiveFedora::Base.find(pid)

					# Remove old publisher.  Preserve other publishers, if present.  Add new publisher.
					current_relationships = obj.relationships(:publisher)
					current_relationships.delete('info:fedora/' + old_publish_target_pid)
					current_relationships << 'info:fedora/' + new_publish_target_pid
					
					obj.clear_relationship(:publisher)
					current_relationships.each do |publisher|
						obj.add_relationship(:publisher, publisher)
					end
					
					obj.save
				rescue SystemExit, Interrupt => e
					# Allow system interrupt (ctrl+c)
					raise e
				rescue Exception => e
					Rails.logger.error "Encountered problem with #{pid}.  Skipping record.  Exception: #{e.message}"
				end
				
				puts "Added publish target to #{pid} | #{counter} of #{total} | #{Time.now - start_time} seconds"
			end
			
    end
  end
 end
