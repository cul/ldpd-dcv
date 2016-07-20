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
      start_time = Time.now
      Dlc::Pids.each(ENV['pid'],ENV['list']) do |pid,current,len|
        Cul::Hydra::Indexer.index_pid(pid)
        puts "Processed #{pid} | #{current} of #{len} | #{Time.now - start_time} seconds"
        sleep(3) if current % 100 == 0
      end
    end
    
    # Same as list task, but multithreaded
    # Note: This is experimental.
    task :list_multithreaded => :environment do
      Dlc::Index.log_level = Logger::INFO
      start_time = Time.now
      threads = (ENV['threads'] || 1).to_i
      
      puts "Performing multithreaded indexing with #{threads} threads."
      
      pool = Thread.pool(threads)
      mutex = Mutex.new
      async_counter = 0
      Dlc::Pids.each(nil,ENV['list']) do |pid,current,len|
        
        # Synchronously	process	first row to reduce risk of autoloading	issues
        if current == 1
          Cul::Hydra::Indexer.index_pid(pid)
          async_counter += 1
          puts "Processed #{pid} | #{async_counter} of #{len} | #{Time.now - start_time} seconds"
          next
        end
        
        pool.process {
          Cul::Hydra::Indexer.index_pid(pid)
          mutex.synchronize do
            async_counter += 1
            puts "Processed #{pid} | #{async_counter} of #{len} | #{Time.now - start_time} seconds"
          end
        }
      end
      pool.shutdown
    end

    task :queue => :environment do
      Dlc::Index.log_level = Logger::INFO
      start_time = Time.now
      Dlc::Pids.each(ENV['pid'],ENV['list']) do |pid,current,len|
        # Queue for reindex
        # Since we only have one solr index right now, all index requests to go the main core and the 'subsite_keys' value does nothing
        Dcv::Queue.index_object({'pid' => pid, 'subsite_keys' => ['catalog']})
        puts "Queued #{current} of #{len}"
      end
    end
  end

  namespace :css do
    task :fix => :environment do
      j = 0
      Dlc::Pids.each(nil,'caggs_css.txt') do |pid,current,len|
        obj = ContentAggregator.find(pid)
        mods = obj.datastreams['descMetadata']
        old_content = mods.content
        new_content = old_content.gsub(/\<originInfo/,'<mods:originInfo')
        new_content ||= old_content
        new_content = new_content.gsub(/\/originInfo/,'/mods:originInfo') || new_content
        if new_content
          mods.content = new_content
          obj.save
          j += 1
          p "processed #{current} of #{len} modifying #{j}\n"
        else
          p "processed #{current} of #{len} skipping changes\n"
        end
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
    
    task :add_missing_dc_types => :environment do
      
      pids = [
        'ldpd:357597',
'ldpd:359416',
'ldpd:359433',
'ldpd:359443',
'ldpd:357941',
'ldpd:358197',
'ldpd:357529',
'ldpd:357541',
'ldpd:357484',
'ldpd:357839',
'ldpd:357549',
'ldpd:358087',
'ldpd:358119',
'ldpd:357676',
'ldpd:357709',
'ldpd:358209',
'ldpd:357409',
'ldpd:357447',
'ldpd:357788',
'ldpd:357468',
'ldpd:357587',
'ldpd:359630',
'ldpd:358069',
'ldpd:357623',
'ldpd:358044',
'ldpd:358004',
'ldpd:357657',
'ldpd:358100',
'ldpd:357779',
'ldpd:359559',
'ldpd:357560',
'ldpd:357858',
'ldpd:357868',
'ldpd:357752',
'ldpd:358000',
'ldpd:357719',
'ldpd:357748',
'ldpd:359493',
'ldpd:357731',
'ldpd:357642',
'ldpd:357877',
'ldpd:357866',
'ldpd:358148',
'ldpd:358138',
'ldpd:357514',
'ldpd:359345',
'ldpd:357870',
'ldpd:359591',
'ldpd:359553',
'ldpd:359396',
'ldpd:359622',
'ldpd:359375',
'ldpd:357729',
'ldpd:357573',
'ldpd:357947',
'ldpd:357845',
'ldpd:357908',
'ldpd:358213',
'ldpd:357985',
'ldpd:357498',
'ldpd:358056',
'ldpd:357663',
'ldpd:357733',
'ldpd:357805',
'ldpd:357713',
'ldpd:358079',
'ldpd:357696',
'ldpd:358058',
'ldpd:357638',
'ldpd:357673',
'ldpd:358189',
'ldpd:357843',
'ldpd:357715',
'ldpd:358117',
'ldpd:358085',
'ldpd:357721',
'ldpd:357723',
'ldpd:358071',
'ldpd:358006',
'ldpd:358048',
'ldpd:357417',
'ldpd:358038',
'ldpd:357995',
'ldpd:358060',
'ldpd:357480',
'ldpd:357512',
'ldpd:357920',
'ldpd:357993',
'ldpd:358174',
'ldpd:357989',
'ldpd:357464',
'ldpd:357661'
      ]
      
      pids.each do |pid|
        obj = ActiveFedora::Base.find(pid)
        dc_type = obj.datastreams['DC'].dc_type[0].to_s
        if dc_type.blank?
          puts "#{pid}: blank"
        else
          puts "dc type NOT blank for #{pid}: #{dc_type}"
        end
        
      end
      
    end
  end

end
