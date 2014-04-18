require "active-fedora"

namespace :dcv do

  task :test => :environment do
    
    lindquist_pid = 'ldpd:130509'
    bag_aggregator = BagAggregator.new(:pid => lindquist_pid)
    puts 'BagAggregator with pid ' + lindquist_pid + ' has ' + bag_aggregator.members.length.to_s + ' members!'
  end

  task :recursively_index_fedora_objects => :environment do
    
    START_TIME = Time.now
    
    #lindquist == burke_lindq == ldpd:130509
    
    ENV["RAILS_ENV"] ||= Rails.env
    
    pid = ENV['pid']
    if pid.blank?
      puts 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
      next
    end
    
    unless Dcv::Utils::FedoraUtils.exists?(pid)
      puts 'Could not find Fedora object with PID: ' + pid
      next
    end
    
    # We found an object with the desired PID. Let's reindex it
    active_fedora_object = ActiveFedora::Base.new(:pid => pid)
    active_fedora_object.update_index
    puts 'Updated topmost pid in this set: ' + pid
    puts 'Recursively retreieving and indexing all members...'
    
    # Now we'll retrieve all children and index them too
    
    #member_query =
    #  'select $pid $cmodel
    #  from <#ri>
    #  where $pid <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '>
    #  and $pid <fedora-model:hasModel> $cmodel
    #  and
    #  (
    #  $cmodel <mulgara:is> <info:fedora/ldpd:ContentAggregator>
    #  or
    #  $cmodel <mulgara:is> <info:fedora/ldpd:BagAggregator>
    #  or
    #  $cmodel <mulgara:is> <info:fedora/ldpd:GenericResource>
    #  )'
  
    #member_query =
    #  'select $child $parent from <#ri>
    #  where walk($child <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '>
    #  and
    #  $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)'
    
    member_query =
      'select $child $parent $cmodel from <#ri>
      where
      walk($child <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '> and $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)
      and
      $child <fedora-model:hasModel> $cmodel'
    
    puts 'Performing query:'
    puts member_query
    
    search_response = Dcv::Utils::FedoraUtils.risearch(
      :query => member_query
    )
    
    total_number_of_members = search_response['results'].length
    puts 'Recursive search found ' + total_number_of_members.to_s + ' members.'
    
    #parents = []
    #children = []
    
    i = 0
    if total_number_of_members > 0
      search_response['results'].each {|result|
        
        # Isolate the pid from the response
        member_pid = result['child'].gsub('info:fedora/', '')
        
        # Index based on type
        case result['cmodel']
        when 'info:fedora/ldpd:BagAggregator'
          active_fedora_object = BagAggregator.new(:pid => member_pid)
          active_fedora_object.update_index
        when 'info:fedora/ldpd:ContentAggregator'
          active_fedora_object = ContentAggregator.new(:pid => member_pid)
          active_fedora_object.update_index
        when 'info:fedora/ldpd:GenericResource'
          #active_fedora_object = GenericResource.new(:pid => member_pid)
          #active_fedora_object.update_index
        else
          # Do nothing
        end
        
        # Display progress
        i += 1
        puts 'Indexed ' + i.to_s + ' of ' + total_number_of_members.to_s + ' (' + member_pid + ')'
      }
    end
    
    puts 'Indexing complete!  Took ' + (Time.now - START_TIME).to_s + ' seconds'
    
    #puts 'parents: ' + parents.length.to_s
    #puts 'unique parents: ' + parents.uniq.length.to_s
    #puts 'children: ' + children.length.to_s
    #puts 'unique children: ' + children.uniq.length.to_s
    #puts 'parents + children: ' + (parents + children).length.to_s
    #puts 'unique parents + children: ' + (parents + children).uniq.length.to_s
    #puts 'parents array includes the top level object in our set? ' + parents.include?('info:fedora/' + pid).to_s
    #puts 'children array includes the top level object in our set? ' + children.include?('info:fedora/' + pid).to_s
    
  end

end