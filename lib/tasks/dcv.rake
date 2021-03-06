module Dlc
  module Pids
    def self.each(pid=nil,list=nil)
      pid = pid ? pid.split(',') : []
      total = pid.count
      open(list) {|b| total += b.count } if list
      counter = 0
      pid.each do |val|
        counter += 1
        yield val, counter, total
      end
      if list
        open(list) do |b|
          b.each do |val|
            val.strip!
            counter += 1
            yield val, counter, total
          end
        end
      end
    end
  end
  module Index
    def self.log_level=(level)

      # Update (2016-02-22): (connection.api.send :logger) returns nil, but we aren't
      # seeing debug level ActiveFedora logging anymore, so we should be okay without this.

      ## -- Don't do debug-level ActiveFedora logging --
      ## initialize the fedora connection if necessary
      #connection = (ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)).connection
      ## the logger accessor is private
      #(connection.api.send :logger).level = level

      Rails.logger.level = level
    end
  end
end
namespace :dcv do

  namespace :rails_cache do
    task :clear => :environment do
      Rails.cache.clear
    end
  end

  namespace :index do
    task :list => :environment do
      Dlc::Index.log_level = Logger::INFO

      softcommit = (ENV['softcommit'] == 'false' ? false : true)

      start_time = Time.now
      Dlc::Pids.each(ENV['pid'],ENV['list']) do |pid,current,len|
        Dcv::Solr::FedoraIndexer.index_pid(pid, false, false, softcommit)
        puts "Processed #{pid} | #{current} of #{len} | #{Time.now - start_time} seconds"
        sleep(3) if current % 100 == 0
      end
    end

    task :queue => :environment do
      Dlc::Index.log_level = Logger::INFO

      softcommit = (ENV['softcommit'] == 'true')

      Dlc::Pids.each(ENV['pid'],ENV['list']) do |pid,current,len|
        # Queue for reindex
        # Since we only have one solr index right now, all index requests to go the main core and the 'subsite_keys' value does nothing
        Dcv::Queue.index_object({'pid' => pid, 'subsite_keys' => ['catalog'], 'softcommit' => softcommit})
        puts "Queued #{current} of #{len}"
      end
    end
  end

  namespace :util do
    task :add_dcv_publish_target => :environment do

      dcv_publish_target = ENV.fetch('target','info:fedora/cul:vmcvdnck2d')
      uri_patt = /^info\:fedora\/.+/
      dcv_publish_target = "info:fedora/#{dcv_publish_target}" unless dcv_publish_target =~ uri_patt
      raise "Bad target: \"#{ENV['target']}\"" unless dcv_publish_target =~ uri_patt
      Dlc::Index.log_level = Logger::INFO
      start_time = Time.now
      Dlc::Pids.each(ENV['pid'],ENV['list']) do |pid,counter,total|
        begin
          obj = ActiveFedora::Base.find(pid)
          # Preserve other publishers, if present.  Add new publisher if it's not already present.
          current_publishers = obj.relationships(:publisher)
          next if current_publishers.include?(dcv_publish_target)
          current_publishers << dcv_publish_target

          obj.clear_relationship(:publisher)
          current_publishers.each { |publisher| obj.add_relationship(:publisher, publisher)}

          obj.save({update_index: false})
        rescue SystemExit, Interrupt => e
          # Allow system interrupt (ctrl+c)
          raise e
        rescue Exception => e
          Rails.logger.error "Encountered problem with #{pid}.  Skipping record.  Exception: #{e.message}"
        end

        puts "Added DLC publish target to #{pid} | #{counter} of #{total} | #{Time.now - start_time} seconds"
      end
    end
  end

end
