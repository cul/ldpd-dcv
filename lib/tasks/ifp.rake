namespace :util do
	namespace :ifp do
		task :add_additional_relationships => :environment do

			if ENV['pid'].present?
				pid = ENV['pid']
			else
				puts 'Error: Please provide a pid, e.g. pid=ldpd:123'
				next
			end

			#if ENV['OFFICE_NAME'].present?
			#	office_name = ENV['OFFICE_NAME']
			#else
			#	puts "Error: Please provide an office name, e.g. OFFICE_NAME=\'Chile and Peru\'"
			#	next
			#end

			# Verify that PID is on list of known IFP pids.
			# Doing this to ensure consistency in office names
			ifp_pid_to_office_mapping = {
				'ldpd:493829' => 'Uganda',
				'ldpd:494394' => 'Guatemala',
				'ldpd:494632' => 'Palestine',
				'ldpd:494830' => 'Tanzania',
				'ldpd:495021' => 'South Africa',
				'ldpd:495324' => 'Thailand',
				'ldpd:493860' => 'Chile and Peru',
				'ldpd:497042' => 'Kenya',
				'ldpd:496363' => 'Senegal',
				'ldpd:495804' => 'Ghana'
			}

			office_name = ifp_pid_to_office_mapping[pid]

			unless ifp_pid_to_office_mapping.has_key?(pid)
				puts "Could not find pid #{pid} in ifp_pid_to_office_mapping hash."
				next
			end

			Dcv::Solr::FedoraIndexer.descend_from(pid, nil, false) do |pid|
				begin
					obj = ActiveFedora::Base.find(pid)

					# Add project
					obj.clear_relationship(:is_constituent_of)
					obj.add_relationship(:is_constituent_of, 'info:fedora/cul:7d7wm37q33')

					# Add publish target, unless this is a BagAggregator
					unless obj.is_a?(BagAggregator)
						obj.clear_relationship(:publisher)
						obj.add_relationship(:publisher, 'info:fedora/cul:rfj6q573w6') # public publish target
						obj.add_relationship(:publisher, 'info:fedora/cul:xwdbrv15p4') # private publish target
					end

					# Add Office Name as string literal
					obj.clear_relationship(:contributor)
					obj.add_relationship(:contributor, office_name, true)
					obj.save
				rescue Exception => e
					puts "Encountered problem with #{pid}.  Skipping record.  Exception: #{e.message}"
				end
			end
		end
		task :convert_aggregator_to_collection => :environment do

			if ENV['pid'].present?
				pid = ENV['pid']
			else
				puts 'Error: Please provide a pid, e.g. pid=ldpd:123'
				next
			end
			predicate = ActiveFedora::Predicates.find_graph_predicate(:has_model)
			old_model = RDF::URI.new("info:fedora/ldpd:ContentAggregator")
			new_model = RDF::URI.new("info:fedora/ldpd:Collection")
			object = ActiveFedora::Base.find(pid,cast: false)
			if object.object_relations[:has_model].include?(old_model.to_s)
				object.object_relations.delete(predicate, old_model)
				object.object_relations.delete(predicate, old_model.to_s)
				object.object_relations.add(predicate, new_model)
				object.save(update_index: false)
				object = object.adapt_to(Collection)
				object.rdf_types!
			end
		end
	end
 end
