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
        'ldpd:357979',
        'ldpd:359377',
        'ldpd:358201',
        'ldpd:357841',
        'ldpd:357750',
        'ldpd:357896',
        'ldpd:357974',
        'ldpd:357807',
        'ldpd:357496',
        'ldpd:359445',
        'ldpd:357888',
        'ldpd:357912',
        'ldpd:357756',
        'ldpd:358140',
        'ldpd:358029',
        'ldpd:357953',
        'ldpd:358146',
        'ldpd:358203',
        'ldpd:359583',
        'ldpd:359626',
        'ldpd:359408',
        'ldpd:359499',
        'ldpd:359454',
        'ldpd:359416',
        'ldpd:359433',
        'ldpd:359484',
        'ldpd:359414',
        'ldpd:359389',
        'ldpd:359537',
        'ldpd:359628',
        'ldpd:359431',
        'ldpd:357898',
        'ldpd:358052',
        'ldpd:357494',
        'ldpd:357786',
        'ldpd:357941',
        'ldpd:358197',
        'ldpd:357529',
        'ldpd:357541',
        'ldpd:357484',
        'ldpd:357839',
        'ldpd:357549',
        'ldpd:358087',
        'ldpd:358119',
        'ldpd:357906',
        'ldpd:359427',
        'ldpd:357758',
        'ldpd:357684',
        'ldpd:357533',
        'ldpd:357698',
        'ldpd:357709',
        'ldpd:358209',
        'ldpd:357409',
        'ldpd:357447',
        'ldpd:357788',
        'ldpd:357468',
        'ldpd:357587',
        'ldpd:359526',
        'ldpd:359594',
        'ldpd:357826',
        'ldpd:357591',
        'ldpd:357577',
        'ldpd:357828',
        'ldpd:357470',
        'ldpd:358104',
        'ldpd:358083',
        'ldpd:357575',
        'ldpd:357916',
        'ldpd:357926',
        'ldpd:357486',
        'ldpd:357457',
        'ldpd:357552',
        'ldpd:357593',
        'ldpd:357997',
        'ldpd:358176',
        'ldpd:358089',
        'ldpd:357754',
        'ldpd:357760',
        'ldpd:358069',
        'ldpd:357623',
        'ldpd:358044',
        'ldpd:358004',
        'ldpd:357657',
        'ldpd:358100',
        'ldpd:357779',
        'ldpd:359460',
        'ldpd:359402',
        'ldpd:357894',
        'ldpd:357703',
        'ldpd:358108',
        'ldpd:358131',
        'ldpd:357430',
        'ldpd:357472',
        'ldpd:358187',
        'ldpd:357560',
        'ldpd:357858',
        'ldpd:357868',
        'ldpd:357752',
        'ldpd:358000',
        'ldpd:357719',
        'ldpd:357939',
        'ldpd:357694',
        'ldpd:357562',
        'ldpd:359530',
        'ldpd:359458',
        'ldpd:359435',
        'ldpd:359555',
        'ldpd:359637',
        'ldpd:359532',
        'ldpd:359493',
        'ldpd:357731',
        'ldpd:357642',
        'ldpd:357877',
        'ldpd:357866',
        'ldpd:357490',
        'ldpd:357615',
        'ldpd:357604',
        'ldpd:357817',
        'ldpd:357900',
        'ldpd:357504',
        'ldpd:357742',
        'ldpd:359398',
        'ldpd:359610',
        'ldpd:359614',
        'ldpd:359400',
        'ldpd:359539',
        'ldpd:359474',
        'ldpd:359514',
        'ldpd:359464',
        'ldpd:359618',
        'ldpd:357423',
        'ldpd:358027',
        'ldpd:358014',
        'ldpd:357506',
        'ldpd:358138',
        'ldpd:357514',
        'ldpd:357690',
        'ldpd:358157',
        'ldpd:357682',
        'ldpd:357958',
        'ldpd:359534',
        'ldpd:359564',
        'ldpd:357466',
        'ldpd:359542',
        'ldpd:359574',
        'ldpd:359470',
        'ldpd:359585',
        'ldpd:359466',
        'ldpd:359602',
        'ldpd:359425',
        'ldpd:359604',
        'ldpd:359579',
        'ldpd:359489',
        'ldpd:357518',
        'ldpd:357404',
        'ldpd:358185',
        'ldpd:358191',
        'ldpd:358205',
        'ldpd:357892',
        'ldpd:357531',
        'ldpd:357548',
        'ldpd:359491',
        'ldpd:359482',
        'ldpd:359606',
        'ldpd:359410',
        'ldpd:359497',
        'ldpd:359591',
        'ldpd:359598',
        'ldpd:359616',
        'ldpd:359495',
        'ldpd:359557',
        'ldpd:359396',
        'ldpd:359622',
        'ldpd:359379',
        'ldpd:359568',
        'ldpd:359540',
        'ldpd:357585',
        'ldpd:357451',
        'ldpd:357794',
        'ldpd:357488',
        'ldpd:357527',
        'ldpd:357634',
        'ldpd:357914',
        'ldpd:357543',
        'ldpd:358193',
        'ldpd:357798',
        'ldpd:357796',
        'ldpd:357686',
        'ldpd:358211',
        'ldpd:357746',
        'ldpd:357655',
        'ldpd:357729',
        'ldpd:357573',
        'ldpd:357947',
        'ldpd:357845',
        'ldpd:357908',
        'ldpd:357705',
        'ldpd:357508',
        'ldpd:357815',
        'ldpd:357717',
        'ldpd:357502',
        'ldpd:358168',
        'ldpd:358195',
        'ldpd:357985',
        'ldpd:357498',
        'ldpd:358056',
        'ldpd:357663',
        'ldpd:358127',
        'ldpd:357688',
        'ldpd:357459',
        'ldpd:358098',
        'ldpd:357434',
        'ldpd:357476',
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
        'ldpd:358159',
        'ldpd:358096',
        'ldpd:357972',
        'ldpd:358215',
        'ldpd:357619',
        'ldpd:357464',
        'ldpd:358040',
        'ldpd:357781',
        'ldpd:357680',
        'ldpd:357411'
      ]
      dc_source_values = {
        'ldpd:357979' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p87.tif',
          'ldpd:359377' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m22.01.tif',
          'ldpd:358201' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.02.tif',
          'ldpd:357841' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.01.tif',
          'ldpd:357750' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p50.02.tif',
          'ldpd:357896' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p84.tif',
          'ldpd:357974' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p89.03.tif',
          'ldpd:357807' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p89.02.tif',
          'ldpd:357496' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p89.01.tif',
          'ldpd:359445' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.36.tif',
          'ldpd:357888' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.03.tif',
          'ldpd:357912' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p45.01.tif',
          'ldpd:357756' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.21.tif',
          'ldpd:358140' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.15.tif',
          'ldpd:358029' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.25.tif',
          'ldpd:357953' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.06.tif',
          'ldpd:358146' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p46.01.tif',
          'ldpd:358203' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p75.01.tif',
          'ldpd:359583' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m12.02.tif',
          'ldpd:359626' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.36.tif',
          'ldpd:359408' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.35.tif',
          'ldpd:359499' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.34.tif',
          'ldpd:359454' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.33.tif',
          'ldpd:359416' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.32.tif',
          'ldpd:359433' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.31.tif',
          'ldpd:359484' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.28.tif',
          'ldpd:359414' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.26.tif',
          'ldpd:359389' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.25.tif',
          'ldpd:359537' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.23.tif',
          'ldpd:359628' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.22.tif',
          'ldpd:359431' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.21.tif',
          'ldpd:357898' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.12.tif',
          'ldpd:358052' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.11.tif',
          'ldpd:357494' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.10.tif',
          'ldpd:357786' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.09.tif',
          'ldpd:357941' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.08.tif',
          'ldpd:358197' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.07.tif',
          'ldpd:357529' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.06.tif',
          'ldpd:357541' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.05.tif',
          'ldpd:357484' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.04.tif',
          'ldpd:357839' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.03.tif',
          'ldpd:357549' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.02.tif',
          'ldpd:358087' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p14.01.tif',
          'ldpd:358119' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.22.tif',
          'ldpd:357906' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.05.tif',
          'ldpd:359427' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.16.tif',
          'ldpd:357758' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_i.tif',
          'ldpd:357684' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_h.tif',
          'ldpd:357533' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_g.tif',
          'ldpd:357698' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_f.tif',
          'ldpd:357709' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_e.tif',
          'ldpd:358209' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_d.tif',
          'ldpd:357409' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_c.tif',
          'ldpd:357447' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_b.tif',
          'ldpd:357788' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p73_a.tif',
          'ldpd:357468' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp41.tif',
          'ldpd:357587' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp32.tif',
          'ldpd:359526' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.39.tif',
          'ldpd:359594' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m18.02.tif',
          'ldpd:357826' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.24.tif',
          'ldpd:357591' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p47.03-2.tif',
          'ldpd:357577' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p77.01.tif',
          'ldpd:357828' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p93.tif',
          'ldpd:357470' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p75.02.tif',
          'ldpd:358104' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.23.tif',
          'ldpd:358083' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p47.04.tif',
          'ldpd:357575' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.04.tif',
          'ldpd:357916' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.20.tif',
          'ldpd:357926' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.21.tif',
          'ldpd:357486' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.27.tif',
          'ldpd:357457' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.24.tif',
          'ldpd:357552' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.22.tif',
          'ldpd:357593' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p09.23.tif',
          'ldpd:357997' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p77.02.tif',
          'ldpd:358176' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.05.tif',
          'ldpd:358089' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp40.tif',
          'ldpd:357754' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp39.tif',
          'ldpd:357760' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp36.tif',
          'ldpd:358069' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp34.tif',
          'ldpd:357623' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp31.tif',
          'ldpd:358044' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp30.tif',
          'ldpd:358004' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp28.tif',
          'ldpd:357657' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp27.tif',
          'ldpd:358100' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp26.tif',
          'ldpd:357779' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp29.tif',
          'ldpd:359460' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m3.04.tif',
          'ldpd:359402' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m26.01.tif',
          'ldpd:357894' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p16.01.tif',
          'ldpd:357703' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p47.02-2.tif',
          'ldpd:358108' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p95.tif',
          'ldpd:358131' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.01.tif',
          'ldpd:357430' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.10.tif',
          'ldpd:357472' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.04.tif',
          'ldpd:358187' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.05.tif',
          'ldpd:357560' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.02.tif',
          'ldpd:357858' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.11.tif',
          'ldpd:357868' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.06.tif',
          'ldpd:357752' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.08.tif',
          'ldpd:358000' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.07.tif',
          'ldpd:357719' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p48.03.tif',
          'ldpd:357939' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p94.tif',
          'ldpd:357694' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p37.02.tif',
          'ldpd:357562' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p37.01.tif',
          'ldpd:359530' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.34.tif',
          'ldpd:359458' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.27.tif',
          'ldpd:359435' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.28.tif',
          'ldpd:359555' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.29.tif',
          'ldpd:359637' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.31.tif',
          'ldpd:359532' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.30.tif',
          'ldpd:359493' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.32.tif',
          'ldpd:357731' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p54.02.tif',
          'ldpd:357642' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p22.01.tif',
          'ldpd:357877' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.28.tif',
          'ldpd:357866' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.14.tif',
          'ldpd:357490' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.03.tif',
          'ldpd:357615' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.17.tif',
          'ldpd:357604' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.29.tif',
          'ldpd:357817' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.30.tif',
          'ldpd:357900' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p54.01.tif',
          'ldpd:357504' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp25.tif',
          'ldpd:357742' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.14.tif',
          'ldpd:359398' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.018.tif',
          'ldpd:359610' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.028.tif',
          'ldpd:359614' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.058.tif',
          'ldpd:359400' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.0112.tif',
          'ldpd:359539' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.0208.tif',
          'ldpd:359474' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.04.tif',
          'ldpd:359514' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.0214.tif',
          'ldpd:359464' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.0224.tif',
          'ldpd:359618' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m90.034.tif',
          'ldpd:357423' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.06.tif',
          'ldpd:358027' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.05.tif',
          'ldpd:358014' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.04.tif',
          'ldpd:357506' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.03.tif',
          'ldpd:358138' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.02.tif',
          'ldpd:357514' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p70.01.tif',
          'ldpd:357690' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.09.tif',
          'ldpd:358157' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.07.tif',
          'ldpd:357682' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.06.tif',
          'ldpd:357958' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p79.tif',
          'ldpd:359534' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.20.tif',
          'ldpd:359564' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.18.tif',
          'ldpd:357466' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p04.02.tif',
          'ldpd:359542' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.14.tif',
          'ldpd:359574' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.13.tif',
          'ldpd:359470' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.11.tif',
          'ldpd:359585' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.09.tif',
          'ldpd:359466' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.08.tif',
          'ldpd:359602' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.07.tif',
          'ldpd:359425' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.06.tif',
          'ldpd:359604' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.04.tif',
          'ldpd:359579' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.03.tif',
          'ldpd:359489' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m24.01.tif',
          'ldpd:357518' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.15.tif',
          'ldpd:357404' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.13.tif',
          'ldpd:358185' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.18.tif',
          'ldpd:358191' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.12.tif',
          'ldpd:358205' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.08.tif',
          'ldpd:357892' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p74.tif',
          'ldpd:357531' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.19.tif',
          'ldpd:357548' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.16.tif',
          'ldpd:359491' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m16.01.tif',
          'ldpd:359482' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.01.tif',
          'ldpd:359606' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.22.tif',
          'ldpd:359410' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.08.tif',
          'ldpd:359497' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.07.tif',
          'ldpd:359591' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.20.tif',
          'ldpd:359598' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m7.01.tif',
          'ldpd:359616' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.17.tif',
          'ldpd:359495' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.05.tif',
          'ldpd:359557' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.04.tif',
          'ldpd:359396' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.03.tif',
          'ldpd:359622' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.02.tif',
          'ldpd:359379' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.10.tif',
          'ldpd:359568' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.16.tif',
          'ldpd:359540' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/masks/rbml_realia_m1.06.tif',
          'ldpd:357585' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p43.02.tif',
          'ldpd:357451' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p43.01.tif',
          'ldpd:357794' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p47.01.tif',
          'ldpd:357488' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.04.tif',
          'ldpd:357527' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p05.08.tif',
          'ldpd:357634' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p05.01.tif',
          'ldpd:357914' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp33.tif',
          'ldpd:357543' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp35.tif',
          'ldpd:358193' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.20.tif',
          'ldpd:357798' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p11.11.tif',
          'ldpd:357796' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p78.01.tif',
          'ldpd:357686' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p54.03.tif',
          'ldpd:358211' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp38.tif',
          'ldpd:357746' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.32.tif',
          'ldpd:357655' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp37.tif',
          'ldpd:357729' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.31.tif',
          'ldpd:357573' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.27.tif',
          'ldpd:357947' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p76.03.tif',
          'ldpd:357845' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p76.02.tif',
          'ldpd:357908' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p76.01.tif',
          'ldpd:357705' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p10.26.tif',
          'ldpd:357508' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.01.tif',
          'ldpd:357815' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.02.tif',
          'ldpd:357717' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p44.01.tif',
          'ldpd:357502' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.08.tif',
          'ldpd:358168' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.14.tif',
          'ldpd:358195' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.20.tif',
          'ldpd:357985' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.04.tif',
          'ldpd:357498' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.03.tif',
          'ldpd:358056' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.07.tif',
          'ldpd:357663' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.05.tif',
          'ldpd:358127' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.02.tif',
          'ldpd:357688' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.10.tif',
          'ldpd:357459' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.13.tif',
          'ldpd:358098' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.19.tif',
          'ldpd:357434' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.12.tif',
          'ldpd:357476' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.09.tif',
          'ldpd:357805' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.06.tif',
          'ldpd:357713' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p13.11.tif',
          'ldpd:358079' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp24.tif',
          'ldpd:357696' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp23.tif',
          'ldpd:358058' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp22.tif',
          'ldpd:357638' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp21.tif',
          'ldpd:357673' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp20.tif',
          'ldpd:358189' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp19.tif',
          'ldpd:357843' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp18.tif',
          'ldpd:357715' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp17.tif',
          'ldpd:358117' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp16.tif',
          'ldpd:358085' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp15.tif',
          'ldpd:357721' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp14.tif',
          'ldpd:357723' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp13.tif',
          'ldpd:358071' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp12.tif',
          'ldpd:358006' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp11.tif',
          'ldpd:358048' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp10.tif',
          'ldpd:357417' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp09.tif',
          'ldpd:358038' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp08.tif',
          'ldpd:357995' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp07.tif',
          'ldpd:358060' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp06.tif',
          'ldpd:357480' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp05.tif',
          'ldpd:357512' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp04.tif',
          'ldpd:357920' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp03.tif',
          'ldpd:357993' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp02.tif',
          'ldpd:358174' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_tsp01.tif',
          'ldpd:358159' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p86.tif',
          'ldpd:358096' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p39.02.tif',
          'ldpd:357972' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p18.01.tif',
          'ldpd:358215' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p18.02.tif',
          'ldpd:357619' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p18.02-2.tif',
          'ldpd:357464' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p18.03.tif',
          'ldpd:358040' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p80.tif',
          'ldpd:357781' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p82.tif',
          'ldpd:357680' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p81.tif',
          'ldpd:357411' => '/ifs/cul/ldpd/fstore/archive/preservation/dm_realia/data/puppets/rbml_realia_p07.01.tif'
      }
      
      pids.each do |pid|
        obj = ActiveFedora::Base.find(pid)
        puts pid
        raise 'dc_type blank!' if obj.datastreams['DC'].dc_type.blank?
        raise 'dc_source blank!' if obj.datastreams['DC'].dc_source.blank?
        
        #obj.datastreams['DC'].dc_source = dc_source_values[pid]
        #obj.datastreams['DC'].dc_type = ['StillImage']
       
        #obj.save(update_index: false)
        
        puts '-- dc_type: ' + obj.datastreams['DC'].dc_type[0].inspect
        puts '-- dc_source: ' + obj.datastreams['DC'].dc_source[0].inspect
        
        #dc_type = obj.datastreams['DC'].dc_type[0].to_s
        #
        #puts "#{pid} dc_type: #{dc_type}"
        #
        #if dc_type.blank?
        #  dc_source = obj.datastreams['DC'].dc_source[0].to_s
        #  if dc_source.end_with?('.tif')
        #    obj.datastreams['DC'].dc_type = ['StillImage']
        #    obj.save(update_index: false)
        #    puts '...updated to StillImage!'
        #  else
        #    raise 'Not a tif: ' + dc_source
        #  end
        #else
        #  puts "No dc_type change needed for #{pid}"
        #end
        
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
