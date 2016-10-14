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
    
    task :identifiers_to_pids_for_spanish_children => :environment do
      
      identifiers = [
        'apt://columbia.edu/prd.spanishchildren/data/1.tif',
'apt://columbia.edu/prd.spanishchildren/data/10.tif',
'apt://columbia.edu/prd.spanishchildren/data/100.tif',
'apt://columbia.edu/prd.spanishchildren/data/101.tif',
'apt://columbia.edu/prd.spanishchildren/data/102.tif',
'apt://columbia.edu/prd.spanishchildren/data/103.tif',
'apt://columbia.edu/prd.spanishchildren/data/104.tif',
'apt://columbia.edu/prd.spanishchildren/data/105.tif',
'apt://columbia.edu/prd.spanishchildren/data/106.tif',
'apt://columbia.edu/prd.spanishchildren/data/107.tif',
'apt://columbia.edu/prd.spanishchildren/data/108.tif',
'apt://columbia.edu/prd.spanishchildren/data/109.tif',
'apt://columbia.edu/prd.spanishchildren/data/11.tif',
'apt://columbia.edu/prd.spanishchildren/data/110.tif',
'apt://columbia.edu/prd.spanishchildren/data/111.tif',
'apt://columbia.edu/prd.spanishchildren/data/112.tif',
'apt://columbia.edu/prd.spanishchildren/data/113.tif',
'apt://columbia.edu/prd.spanishchildren/data/114.tif',
'apt://columbia.edu/prd.spanishchildren/data/115.tif',
'apt://columbia.edu/prd.spanishchildren/data/116.tif',
'apt://columbia.edu/prd.spanishchildren/data/117.tif',
'apt://columbia.edu/prd.spanishchildren/data/118.tif',
'apt://columbia.edu/prd.spanishchildren/data/119.tif',
'apt://columbia.edu/prd.spanishchildren/data/12.tif',
'apt://columbia.edu/prd.spanishchildren/data/120.tif',
'apt://columbia.edu/prd.spanishchildren/data/121.tif',
'apt://columbia.edu/prd.spanishchildren/data/122.tif',
'apt://columbia.edu/prd.spanishchildren/data/123.tif',
'apt://columbia.edu/prd.spanishchildren/data/124.tif',
'apt://columbia.edu/prd.spanishchildren/data/125.tif',
'apt://columbia.edu/prd.spanishchildren/data/126.tif',
'apt://columbia.edu/prd.spanishchildren/data/127.tif',
'apt://columbia.edu/prd.spanishchildren/data/128.tif',
'apt://columbia.edu/prd.spanishchildren/data/129.tif',
'apt://columbia.edu/prd.spanishchildren/data/13.tif',
'apt://columbia.edu/prd.spanishchildren/data/130.tif',
'apt://columbia.edu/prd.spanishchildren/data/131.tif',
'apt://columbia.edu/prd.spanishchildren/data/132.tif',
'apt://columbia.edu/prd.spanishchildren/data/133.tif',
'apt://columbia.edu/prd.spanishchildren/data/134.tif',
'apt://columbia.edu/prd.spanishchildren/data/135.tif',
'apt://columbia.edu/prd.spanishchildren/data/136.tif',
'apt://columbia.edu/prd.spanishchildren/data/137.tif',
'apt://columbia.edu/prd.spanishchildren/data/138.tif',
'apt://columbia.edu/prd.spanishchildren/data/139.tif',
'apt://columbia.edu/prd.spanishchildren/data/14.tif',
'apt://columbia.edu/prd.spanishchildren/data/140.tif',
'apt://columbia.edu/prd.spanishchildren/data/141.tif',
'apt://columbia.edu/prd.spanishchildren/data/142.tif',
'apt://columbia.edu/prd.spanishchildren/data/143.tif',
'apt://columbia.edu/prd.spanishchildren/data/144.tif',
'apt://columbia.edu/prd.spanishchildren/data/145.tif',
'apt://columbia.edu/prd.spanishchildren/data/146.tif',
'apt://columbia.edu/prd.spanishchildren/data/147.tif',
'apt://columbia.edu/prd.spanishchildren/data/148.tif',
'apt://columbia.edu/prd.spanishchildren/data/149.tif',
'apt://columbia.edu/prd.spanishchildren/data/15.tif',
'apt://columbia.edu/prd.spanishchildren/data/150.tif',
'apt://columbia.edu/prd.spanishchildren/data/151.tif',
'apt://columbia.edu/prd.spanishchildren/data/152.tif',
'apt://columbia.edu/prd.spanishchildren/data/153.tif',
'apt://columbia.edu/prd.spanishchildren/data/154_800.tif',
'apt://columbia.edu/prd.spanishchildren/data/16.tif',
'apt://columbia.edu/prd.spanishchildren/data/17.tif',
'apt://columbia.edu/prd.spanishchildren/data/18.tif',
'apt://columbia.edu/prd.spanishchildren/data/19.tif',
'apt://columbia.edu/prd.spanishchildren/data/2.tif',
'apt://columbia.edu/prd.spanishchildren/data/20.tif',
'apt://columbia.edu/prd.spanishchildren/data/21.tif',
'apt://columbia.edu/prd.spanishchildren/data/22.tif',
'apt://columbia.edu/prd.spanishchildren/data/23.tif',
'apt://columbia.edu/prd.spanishchildren/data/24.tif',
'apt://columbia.edu/prd.spanishchildren/data/25.tif',
'apt://columbia.edu/prd.spanishchildren/data/26.tif',
'apt://columbia.edu/prd.spanishchildren/data/27.tif',
'apt://columbia.edu/prd.spanishchildren/data/28.tif',
'apt://columbia.edu/prd.spanishchildren/data/29.tif',
'apt://columbia.edu/prd.spanishchildren/data/3.tif',
'apt://columbia.edu/prd.spanishchildren/data/30.tif',
'apt://columbia.edu/prd.spanishchildren/data/31.tif',
'apt://columbia.edu/prd.spanishchildren/data/32.tif',
'apt://columbia.edu/prd.spanishchildren/data/33.tif',
'apt://columbia.edu/prd.spanishchildren/data/34.tif',
'apt://columbia.edu/prd.spanishchildren/data/35.tif',
'apt://columbia.edu/prd.spanishchildren/data/36.tif',
'apt://columbia.edu/prd.spanishchildren/data/37.tif',
'apt://columbia.edu/prd.spanishchildren/data/38.tif',
'apt://columbia.edu/prd.spanishchildren/data/39.tif',
'apt://columbia.edu/prd.spanishchildren/data/4.tif',
'apt://columbia.edu/prd.spanishchildren/data/40.tif',
'apt://columbia.edu/prd.spanishchildren/data/41.tif',
'apt://columbia.edu/prd.spanishchildren/data/42.tif',
'apt://columbia.edu/prd.spanishchildren/data/43.tif',
'apt://columbia.edu/prd.spanishchildren/data/44.tif',
'apt://columbia.edu/prd.spanishchildren/data/45.tif',
'apt://columbia.edu/prd.spanishchildren/data/46.tif',
'apt://columbia.edu/prd.spanishchildren/data/47.tif',
'apt://columbia.edu/prd.spanishchildren/data/48.tif',
'apt://columbia.edu/prd.spanishchildren/data/49.tif',
'apt://columbia.edu/prd.spanishchildren/data/5.tif',
'apt://columbia.edu/prd.spanishchildren/data/50.tif',
'apt://columbia.edu/prd.spanishchildren/data/51.tif',
'apt://columbia.edu/prd.spanishchildren/data/52.tif',
'apt://columbia.edu/prd.spanishchildren/data/53.tif',
'apt://columbia.edu/prd.spanishchildren/data/54.tif',
'apt://columbia.edu/prd.spanishchildren/data/55.tif',
'apt://columbia.edu/prd.spanishchildren/data/56_800.tif',
'apt://columbia.edu/prd.spanishchildren/data/57.tif',
'apt://columbia.edu/prd.spanishchildren/data/58.tif',
'apt://columbia.edu/prd.spanishchildren/data/59.tif',
'apt://columbia.edu/prd.spanishchildren/data/6.tif',
'apt://columbia.edu/prd.spanishchildren/data/60.tif',
'apt://columbia.edu/prd.spanishchildren/data/61.tif',
'apt://columbia.edu/prd.spanishchildren/data/62.tif',
'apt://columbia.edu/prd.spanishchildren/data/63.tif',
'apt://columbia.edu/prd.spanishchildren/data/64.tif',
'apt://columbia.edu/prd.spanishchildren/data/65.tif',
'apt://columbia.edu/prd.spanishchildren/data/66.tif',
'apt://columbia.edu/prd.spanishchildren/data/67.tif',
'apt://columbia.edu/prd.spanishchildren/data/68.tif',
'apt://columbia.edu/prd.spanishchildren/data/69.tif',
'apt://columbia.edu/prd.spanishchildren/data/7.tif',
'apt://columbia.edu/prd.spanishchildren/data/70.tif',
'apt://columbia.edu/prd.spanishchildren/data/71.tif',
'apt://columbia.edu/prd.spanishchildren/data/72.tif',
'apt://columbia.edu/prd.spanishchildren/data/73_800.tif',
'apt://columbia.edu/prd.spanishchildren/data/74.tif',
'apt://columbia.edu/prd.spanishchildren/data/75.tif',
'apt://columbia.edu/prd.spanishchildren/data/76.tif',
'apt://columbia.edu/prd.spanishchildren/data/77.tif',
'apt://columbia.edu/prd.spanishchildren/data/78.tif',
'apt://columbia.edu/prd.spanishchildren/data/79.tif',
'apt://columbia.edu/prd.spanishchildren/data/8.tif',
'apt://columbia.edu/prd.spanishchildren/data/80.tif',
'apt://columbia.edu/prd.spanishchildren/data/81.tif',
'apt://columbia.edu/prd.spanishchildren/data/82.tif',
'apt://columbia.edu/prd.spanishchildren/data/83_800.tif',
'apt://columbia.edu/prd.spanishchildren/data/84.tif',
'apt://columbia.edu/prd.spanishchildren/data/85.tif',
'apt://columbia.edu/prd.spanishchildren/data/86.tif',
'apt://columbia.edu/prd.spanishchildren/data/87.tif',
'apt://columbia.edu/prd.spanishchildren/data/88.tif',
'apt://columbia.edu/prd.spanishchildren/data/89.tif',
'apt://columbia.edu/prd.spanishchildren/data/9.tif',
'apt://columbia.edu/prd.spanishchildren/data/90.tif',
'apt://columbia.edu/prd.spanishchildren/data/91.tif',
'apt://columbia.edu/prd.spanishchildren/data/92.tif',
'apt://columbia.edu/prd.spanishchildren/data/93.tif',
'apt://columbia.edu/prd.spanishchildren/data/94.tif',
'apt://columbia.edu/prd.spanishchildren/data/95.tif',
'apt://columbia.edu/prd.spanishchildren/data/96.tif',
'apt://columbia.edu/prd.spanishchildren/data/97.tif',
'apt://columbia.edu/prd.spanishchildren/data/98.tif',
'apt://columbia.edu/prd.spanishchildren/data/99.tif',
'ldpd.spanishchildren.1',
'ldpd.spanishchildren.10',
'ldpd.spanishchildren.100',
'ldpd.spanishchildren.101',
'ldpd.spanishchildren.102',
'ldpd.spanishchildren.103',
'ldpd.spanishchildren.104',
'ldpd.spanishchildren.105',
'ldpd.spanishchildren.106',
'ldpd.spanishchildren.107',
'ldpd.spanishchildren.108',
'ldpd.spanishchildren.109',
'ldpd.spanishchildren.11',
'ldpd.spanishchildren.110',
'ldpd.spanishchildren.111',
'ldpd.spanishchildren.112',
'ldpd.spanishchildren.113',
'ldpd.spanishchildren.114',
'ldpd.spanishchildren.115',
'ldpd.spanishchildren.116',
'ldpd.spanishchildren.117',
'ldpd.spanishchildren.118',
'ldpd.spanishchildren.119',
'ldpd.spanishchildren.12',
'ldpd.spanishchildren.120',
'ldpd.spanishchildren.121',
'ldpd.spanishchildren.122',
'ldpd.spanishchildren.123',
'ldpd.spanishchildren.124',
'ldpd.spanishchildren.125',
'ldpd.spanishchildren.126',
'ldpd.spanishchildren.127',
'ldpd.spanishchildren.128',
'ldpd.spanishchildren.129',
'ldpd.spanishchildren.13',
'ldpd.spanishchildren.130',
'ldpd.spanishchildren.131',
'ldpd.spanishchildren.132',
'ldpd.spanishchildren.133',
'ldpd.spanishchildren.134',
'ldpd.spanishchildren.135',
'ldpd.spanishchildren.136',
'ldpd.spanishchildren.137',
'ldpd.spanishchildren.138',
'ldpd.spanishchildren.139',
'ldpd.spanishchildren.14',
'ldpd.spanishchildren.140',
'ldpd.spanishchildren.141',
'ldpd.spanishchildren.142',
'ldpd.spanishchildren.143',
'ldpd.spanishchildren.144',
'ldpd.spanishchildren.145',
'ldpd.spanishchildren.146',
'ldpd.spanishchildren.147',
'ldpd.spanishchildren.148',
'ldpd.spanishchildren.149',
'ldpd.spanishchildren.15',
'ldpd.spanishchildren.150',
'ldpd.spanishchildren.151',
'ldpd.spanishchildren.152',
'ldpd.spanishchildren.153',
'ldpd.spanishchildren.154',
'ldpd.spanishchildren.16',
'ldpd.spanishchildren.17',
'ldpd.spanishchildren.18',
'ldpd.spanishchildren.19',
'ldpd.spanishchildren.2',
'ldpd.spanishchildren.20',
'ldpd.spanishchildren.21',
'ldpd.spanishchildren.22',
'ldpd.spanishchildren.23',
'ldpd.spanishchildren.24',
'ldpd.spanishchildren.25',
'ldpd.spanishchildren.26',
'ldpd.spanishchildren.27',
'ldpd.spanishchildren.28',
'ldpd.spanishchildren.29',
'ldpd.spanishchildren.3',
'ldpd.spanishchildren.30',
'ldpd.spanishchildren.31',
'ldpd.spanishchildren.32',
'ldpd.spanishchildren.33',
'ldpd.spanishchildren.34',
'ldpd.spanishchildren.35',
'ldpd.spanishchildren.36',
'ldpd.spanishchildren.37',
'ldpd.spanishchildren.38',
'ldpd.spanishchildren.39',
'ldpd.spanishchildren.4',
'ldpd.spanishchildren.40',
'ldpd.spanishchildren.41',
'ldpd.spanishchildren.42',
'ldpd.spanishchildren.43',
'ldpd.spanishchildren.44',
'ldpd.spanishchildren.45',
'ldpd.spanishchildren.46',
'ldpd.spanishchildren.47',
'ldpd.spanishchildren.48',
'ldpd.spanishchildren.49',
'ldpd.spanishchildren.5',
'ldpd.spanishchildren.50',
'ldpd.spanishchildren.51',
'ldpd.spanishchildren.52',
'ldpd.spanishchildren.53',
'ldpd.spanishchildren.54',
'ldpd.spanishchildren.55',
'ldpd.spanishchildren.56',
'ldpd.spanishchildren.57',
'ldpd.spanishchildren.58',
'ldpd.spanishchildren.59',
'ldpd.spanishchildren.6',
'ldpd.spanishchildren.60',
'ldpd.spanishchildren.61',
'ldpd.spanishchildren.62',
'ldpd.spanishchildren.63',
'ldpd.spanishchildren.64',
'ldpd.spanishchildren.65',
'ldpd.spanishchildren.66',
'ldpd.spanishchildren.67',
'ldpd.spanishchildren.68',
'ldpd.spanishchildren.69',
'ldpd.spanishchildren.7',
'ldpd.spanishchildren.70',
'ldpd.spanishchildren.71',
'ldpd.spanishchildren.72',
'ldpd.spanishchildren.73',
'ldpd.spanishchildren.74',
'ldpd.spanishchildren.75',
'ldpd.spanishchildren.76',
'ldpd.spanishchildren.77',
'ldpd.spanishchildren.78',
'ldpd.spanishchildren.79',
'ldpd.spanishchildren.8',
'ldpd.spanishchildren.80',
'ldpd.spanishchildren.81',
'ldpd.spanishchildren.82',
'ldpd.spanishchildren.83',
'ldpd.spanishchildren.84',
'ldpd.spanishchildren.85',
'ldpd.spanishchildren.86',
'ldpd.spanishchildren.87',
'ldpd.spanishchildren.88',
'ldpd.spanishchildren.89',
'ldpd.spanishchildren.9',
'ldpd.spanishchildren.90',
'ldpd.spanishchildren.91',
'ldpd.spanishchildren.92',
'ldpd.spanishchildren.93',
'ldpd.spanishchildren.94',
'ldpd.spanishchildren.95',
'ldpd.spanishchildren.96',
'ldpd.spanishchildren.97',
'ldpd.spanishchildren.98',
'ldpd.spanishchildren.99'
      ]
      identifiers_to_pids = {}
      
      start_time = Time.now
      identifiers.each_with_index do |identifier, i|
        puts 'Processed ' + i.to_s
        pid = Cul::Hydra::RisearchMembers.get_pid_for_identifier(identifier, false)
        identifiers_to_pids[identifier] = pid if pid.present?
      end
      
      end_time = Time.now - start_time
      
      puts 'Search took: ' + end_time.to_s + ' seconds'
      puts 'Num identifiers: ' + identifiers.length.to_s
      puts 'Num pids found for identifiers: ' + identifiers_to_pids.length.to_s
      puts 'pids not found for: ' + (identifiers - identifiers_to_pids.keys).sort.inspect
      
      # Output spreadsheet mapping filenames to pids, preserving original filename order and leaving blanks for when filename was not found for pid
      
      CSV.open(File.join(Rails.root, 'lib', 'tasks', 'identifiers_to_pids_out.csv'), "w") do |csv|
        identifiers.each do |identifier|
          csv << [identifier, (identifiers_to_pids[identifier] || '')]
        end
      end
      
    end
    
    
    task :fix_dc_types => :environment do
      
      pids = [
        'ldpd:492654',
'ldpd:492568',
'ldpd:492741',
'ldpd:492649',
'ldpd:367930',
'ldpd:492567',
'ldpd:492506',
'ldpd:492642',
'ldpd:492739',
'ldpd:492698',
'ldpd:372087',
'ldpd:492546',
'ldpd:492540',
'ldpd:492639',
'ldpd:492564',
'ldpd:492517',
'ldpd:372094',
'ldpd:492708',
'ldpd:492554',
'ldpd:369518',
'ldpd:492613',
'ldpd:492619',
'ldpd:492675',
'ldpd:492678',
'ldpd:492504',
'ldpd:492754',
'ldpd:492638',
'ldpd:363127',
'ldpd:492532',
'ldpd:366283',
'ldpd:492549',
'ldpd:492509',
'ldpd:492629',
'ldpd:492607',
'ldpd:492740',
'ldpd:375676',
'ldpd:492550',
'ldpd:374396',
'ldpd:492539',
'ldpd:492681',
'ldpd:492645',
'ldpd:492551',
'ldpd:492625',
'ldpd:492632',
'ldpd:492674',
'ldpd:492523',
'ldpd:492525',
'ldpd:492518',
'ldpd:492620',
'ldpd:492621',
'ldpd:492513',
'ldpd:492555',
'ldpd:492561',
'ldpd:492677',
'ldpd:492563',
'ldpd:363142',
'ldpd:374523',
'ldpd:492553',
'ldpd:492566',
'ldpd:492640',
'ldpd:370011',
'ldpd:362347',
'ldpd:492626',
'ldpd:492528',
'ldpd:492709',
'ldpd:492524',
'ldpd:373956',
'ldpd:492624',
'ldpd:492571',
'ldpd:484851',
'ldpd:366016',
'ldpd:365982',
'ldpd:492527',
'ldpd:492560',
'ldpd:492543',
'ldpd:492516',
'ldpd:492711',
'ldpd:492507',
'ldpd:492562',
'ldpd:372009',
'ldpd:492650',
'ldpd:367605',
'ldpd:492565',
'ldpd:492652',
'ldpd:492508',
'ldpd:492636',
'ldpd:373877',
'ldpd:492505',
'ldpd:492616',
'ldpd:492633',
'ldpd:369945',
'ldpd:492552',
'ldpd:492512',
'ldpd:492530',
'ldpd:492646',
'ldpd:492570',
'ldpd:367609',
'ldpd:492556',
'ldpd:492651',
'ldpd:492744',
'ldpd:492748',
'ldpd:492702',
'ldpd:492680',
'ldpd:492609',
'ldpd:492542',
'ldpd:492715',
'ldpd:492538',
'ldpd:492751',
'ldpd:492753',
'ldpd:492635',
'ldpd:372104',
'ldpd:365876',
'ldpd:374482',
'ldpd:403470',
'ldpd:492617',
'ldpd:492520',
'ldpd:492756',
'ldpd:492526',
'ldpd:374992',
'ldpd:492673',
'ldpd:492648',
'ldpd:374478',
'ldpd:492743',
'ldpd:492608',
'ldpd:492547',
'ldpd:492618',
'ldpd:492533',
'ldpd:492514',
'ldpd:365871',
'ldpd:492700',
'ldpd:492647',
'ldpd:363982',
'ldpd:492569',
'ldpd:492712',
'ldpd:492697',
'ldpd:163831',
'ldpd:492747',
'ldpd:492710',
'ldpd:492714',
'ldpd:492545',
'ldpd:492705',
'ldpd:492623',
'ldpd:492745',
'ldpd:492701',
'ldpd:492713',
'ldpd:492558',
'ldpd:492672',
'ldpd:492657',
'ldpd:492544',
'ldpd:492738',
'ldpd:492737',
'ldpd:492752',
'ldpd:492628',
'ldpd:492541',
'ldpd:492521',
'ldpd:492641',
'ldpd:492656',
'ldpd:492750',
'ldpd:492612',
'ldpd:492679',
'ldpd:492655',
'ldpd:484052',
'ldpd:492534',
'ldpd:492704',
'ldpd:492515',
'ldpd:492746',
'ldpd:492535',
'ldpd:492622',
'ldpd:492531',
'ldpd:492631',
'ldpd:492510',
'ldpd:492637',
'ldpd:364248',
'ldpd:364126',
'ldpd:492511',
'ldpd:492749',
'ldpd:492614',
'ldpd:492703',
'ldpd:492699',
'ldpd:492519',
'ldpd:492643',
'ldpd:492676',
'ldpd:492634',
'ldpd:492536',
'ldpd:492522',
'ldpd:492557',
'ldpd:492630',
'ldpd:492548',
'ldpd:492644',
'ldpd:492755',
'ldpd:492653',
'ldpd:492610',
'ldpd:492706',
'ldpd:362267',
'ldpd:492559',
'ldpd:492615',
'ldpd:492742',
'ldpd:492529',
'ldpd:492611',
'ldpd:492627'
      ]
      
      pids.each do |pid|
        obj = ActiveFedora::Base.find(pid)
        
        obj.datastreams['DC'].dc_type = 'StillImage'
        obj.datastreams['DC'].dc_format = 'image/tiff'
        obj.save
        puts pid + ' done'
      end
      
    end
    
    task :update_dc_type_for_ifp_objects => :environment do
      
      conversion_mapping = {
        'ldpd:556620' => 'UnstructuredText',
        'ldpd:556683' => 'PageDescription',
        'ldpd:558136' => 'UnstructuredText',
        'ldpd:556674' => 'Spreadsheet',
        'ldpd:556485' => 'UnstructuredText',
        'ldpd:540516' => 'PageDescription',
        'ldpd:514698' => 'UnstructuredText'
      }
      
      conversion_mapping.each do |pid, new_dc_type|
        obj = ActiveFedora::Base.find(pid)
        #puts obj.datastreams['DC'].dc_type
        
        dc_type = obj.datastreams['DC'].dc_type = [new_dc_type]
        obj.save(update_index: true)
      end
      
    end
    
    task :get_filepaths_for_objects => :environment do
      identifiers = ['apt://columbia.edu/prd.custord/data/2012/order#120092/1200920002.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920003.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920004.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920005.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920006.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920007.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920008.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920009.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920010.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920011.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920012.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920014.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920015.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920016.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920017.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920018.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920019.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920020.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920020a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920021.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920022.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920023.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920024.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920025.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920026.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920027.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920028.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920029.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920030.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920031.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920032.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920033.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920034.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920035.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920036.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920037.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920038.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920039.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920040.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920041.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920042.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920043.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920044.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920045.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920046.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920047.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920048.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920049.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920050.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920051.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920052.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920053.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920054.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920055.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920056.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920057.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920058.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920059.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920060.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920061.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920062.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920063.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920064.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920065.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920066.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920067.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920068.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920069.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920070.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920071.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920073.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920074.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920075.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920076.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920077.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920078.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920079.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920080.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920081.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920082.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920083.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920084.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920085.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920086.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920087.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920088.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920089.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920090.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920091.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920092.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920093.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920094.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920095.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920096.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920097.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920098.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920099.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920100.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920101.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920102.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920103.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920104.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920105.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920106.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920107.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920108.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920109.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920110.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920111.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920112.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920113.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920114.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920115.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920116.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920117.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920118.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920119.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920120.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920121.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920122.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920123.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920124.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920125.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920126.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920127.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920128.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920129.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920130.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920131.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920132.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920133.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920134.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920135.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920136.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920137.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920138.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920139.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920140.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920141.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920142.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920143.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920144a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920144b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920144c.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920144d.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920145.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920146.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920147a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920147b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920147c.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920148.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920149.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920150.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920151.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920152.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920153.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920154.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920155.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920156.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920157.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920158.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920159.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920160.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920162.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920163.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920164.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920165.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920166.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920167.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920168.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920169.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920170.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920171.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920172.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920173.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920174.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920176.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920177.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920178.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920179.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920180a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920180b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920181.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920182.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920183.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920184.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920185a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920185b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920186.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920187.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920188a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920188b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920189.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920190.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920191a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920191b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920192.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920193.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920194a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920194b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920195.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920196.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920197.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920198.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920199.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920200.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920201a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920201b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920201c.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920202.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920203a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920203b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920204.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920205.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920206.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920207a.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920207b.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920208.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920209.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920210.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920211.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920212.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/1200920213.tif',
        'info:fedora/ldpd:156405/structMetadata/2012/order%23120092/Color',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920088_colorcheker_300_.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920089_colorcheke_300_.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920142_colorchecker_300.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920146_Colorchecker_300.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920160_colorchecker_300.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920173_colorchecker_300.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/1200920_colorchecker_400.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_Colorchecker_400_4-27-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_400-5-3-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_400_5-2-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_600.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_600_5-1-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_600_5-3-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_600_5-9-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchecker_600_5_4_2012_20359.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorcheker_400_5-9-12_20674.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/120092_colorchrker_400_5-8-12.tif',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Color/Thumbs.db',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Scanning metadata UPD_order_120092.xls',
        'apt://columbia.edu/prd.custord/data/2012/order#120092/Thumbs.db'
      ]
      
      identifiers.each_with_index do |identifier, i|
        #print "\rProcessing...#{i+1} of #{num_results}"
        
        # Retrieve pid and path for identifier
        begin
          pid = Cul::Hydra::RisearchMembers.get_pid_for_identifier(identifier, false)
          
          if pid == nil
            puts 'Skipped identifier (no pid found): ' + identifier.inspect
          else
            obj = ActiveFedora::Base.find(pid)
            raise 'Not an asset: ' + obj.pid unless obj.is_a?(GenericResource)
            filepath = obj.datastreams['DC'].dc_source[0].to_s
            puts "#{obj.pid},\"#{File.basename(filepath)}\",\"#{filepath}\""
          end
          
        rescue RestClient::Unauthorized
          puts 'Encountered 401 Unauthorized while attempting to get MODS at: ' + mods_url
        end
      end
      
    end
    
    
  end

end
