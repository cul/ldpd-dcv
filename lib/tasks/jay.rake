require 'digest'
LOGGER = Logger.new(STDOUT)
module Util
  module Jay
    def self.update_if_changed!(obj, path)
      if obj and path
        has_checksum = false
        content_changed = false
        checksum = nil
        checksum_type = nil
        ds = obj.datastreams['descMetadata']
        if ds.checksum and ds.checksum != 'none'
          has_checksum = true
          checksum = ds.checksum
          checksum_type = ds.checksumType
        else
          content = ds.content
          md5 = Digest::MD5.new
          md5.update(content)
          checksum = md5.hexdigest
          checksum_type = 'MD5'
        end
        unless File.exists?(path)
          LOGGER.warn "No file at #{path}"
          return
        end
        new_content = nil
        open(path) { |blob| new_content = blob.read }
        # stripping PI and terminal newline to verify checksum
        new_content.sub!(/\<\?.*\?\>\n/,'')
        new_content.strip!
        md5 = Digest::MD5.new
        md5.update(new_content)
        new_checksum = md5.hexdigest
        new_checksum_type = 'MD5'
        content_changed = (new_checksum != checksum)
        if content_changed
          ds.content = new_content
          ds.checksumType = new_checksum_type
        elsif !has_checksum
          ds.checksum = checksum
          ds.checksumType = checksum_type
        end
        obj.save
      else
        LOGGER.info("No object")
      end
    end
    def self.parse_id(mods_path)
      fname = File.basename(mods_path)
      fname.sub!(/_mods\.xml$/,'')
      fname
    end
    def self.mods_manifest(fpath)
      open(fpath) do |blob|
        return blob.collect {|entry| entry.strip!; [parse_id(entry), entry]}.to_h 
      end
    end
    def self.csv_map(fpath, flip=false)
      open(fpath) do |blob|
        return blob.collect {|entry| entry.strip!; p = entry.split(',')[0..1]; flip ? p.reverse : p }.to_h
      end
    end
    def self.next_pid(namespace="ldpd")
      ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
      repo = ActiveFedora::Base.fedora_connection[0].connection
      pid = nil
      begin
        pid = repo.mint(namespace: namespace)
      end while self.exists? pid
      pid
    end
    def self.exists?(pid)
      begin
        return ActiveFedora::Base.exists? pid
      rescue
        return false
      end
    end
    def self.log_level(level)
      # Update (2016-02-22): (connection.api.send :logger) returns nil, but we aren't
      # seeing debug level ActiveFedora logging anymore, so we should be okay without this.
      
      ## initialize the fedora connection if necessary
      #connection = (ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)).connection
      ## the logger accessor is private
      #(connection.api.send :logger).level = level
    end
  end
end

module ActiveFedora
  VERSION = '7.1.0'
end

namespace :util do
  namespace :jay do
    
    task :map_identifiers_to_pids => :environment do
      
      Dlc::Index.log_level = Logger::INFO
      
      path_to_outfile = ENV['outfile']
    
      if path_to_outfile.blank?
        puts 'Error: Missing required argument: outfile=/path/to/outfile.csv'
        next
      end
      
      pids = Cul::Hydra::RisearchMembers.get_project_constituent_pids('cul:rjdfn2z3d0', false)
      total = pids.length
      
      File.open(path_to_outfile, 'w') { |file|
        pids.each_with_index do |pid, i|
          obj = ActiveFedora::Base.find(pid)
          if obj.datastreams['DC'] && obj.datastreams['DC'].dc_identifier
            jay_identifier = obj.datastreams['DC'].dc_identifier.select{|element| element.start_with?('columbia.jay')}.first
            file.write("#{jay_identifier},#{pid}\n")
          end
          puts "Processed #{i+1} of #{total}" if (i+1)%100 == 0
        end
      }
      
    end
    
    task :add_publish_targets => :environment do
      
      Dlc::Index.log_level = Logger::INFO
      
      # Find all Jay project records
      pids = Cul::Hydra::RisearchMembers.get_project_constituent_pids('cul:rjdfn2z3d0', false)
      total = pids.length
      puts "Found #{total} project members."
      
      # And add the Jay publish target to any project members that don't have the publish target
      num_records_modified = 0
      
      pids.each_with_index do |pid, i|
        obj = ActiveFedora::Base.find(pid)
        if obj.relationships(:publisher).blank?
          puts 'Found missing publisher: ' + pid
          obj.add_relationship(:publisher, 'info:fedora/cul:vmcvdnck2d')
          obj.save
          num_records_modified += 1
        end
        puts "Processed #{i+1} of #{total}" if (i+1)%100 == 0
      end
      
      puts "Done. Modified #{num_records_modified} records."
      
    end
    
    task :load_mods => :environment do
      jay_prefix = ENV['jay_mods_dir']
      manifest = Util::Jay.mods_manifest(File.join(jay_prefix, 'manifest.txt'))
      pid_list = (ENV['pid_list'] ||= 'jay_cagg_ids.txt')
      existing = Util::Jay.csv_map(pid_list,true)
      missing = manifest.select {|k| !existing.include? k }
      puts "New caggs: #{missing.size} of #{manifest.size} (#{existing.size} existing)"
      missing.each do |jay_id,mods_path|
        unless jay_id =~ /columbia\.jay\.\d+/
          LOGGER.info "SKIP malformed Jay ID #{jay_id}"
          next
        end
        cagg = ContentAggregator.search_repo(identifier: jay_id).first
        if cagg
          LOGGER.info "SKIP cagg exists: #{mods_path}"
          next  # only the new ones
        end
        mods = nil
        open(File.join(jay_prefix,mods_path)) {|blob| mods = blob.read}
        unless mods && mods =~ /identifier\stype/
          LOGGER.info "SKIP MODS was empty: #{mods_path}"
          next
        end
        cagg = ContentAggregator.new(:pid=>Util::Jay.next_pid)
        cagg.datastreams["DC"].update_values({[:dc_identifier] => jay_id})
        cagg.datastreams["DC"].update_values({[:dc_type] => 'InteractiveResource'})
        cagg.add_relationship(:is_constituent_of, 'info:fedora/cul:rjdfn2z3d0')
        cagg.datastreams["descMetadata"].content = mods
        cagg.save
        LOGGER.info "ADD #{cagg.pid} #{mods_path}"
      end
    end
    task :add_constituent => :environment do
      pid_list = ENV['pid_list']

      return unless pid_list
      Util::Jay.log_level(Logger::INFO)
      i = 0
      open(pid_list) do |blob|
        blob.each do |line|
          line.strip!
          i += 1
          cagg = ActiveFedora::Base.find(line)
          if !cagg
            LOGGER.info("#{i} SKIP    No object found for #{line}")
            next
          end
          if cagg.relationships(:is_constituent_of).include? 'info:fedora/cul:rjdfn2z3d0'
            LOGGER.info("#{i} REINDEX #{line} :is_constituent_of <info:fedora/cul:rjdfn2z3d0>")
            cagg.update_index
            next
          else
            cagg.add_relationship(:is_constituent_of, 'info:fedora/cul:rjdfn2z3d0')
            cagg.save
            LOGGER.info("#{i} UPDATE  #{line} :is_constituent_of <info:fedora/cul:rjdfn2z3d0>")
          end
        end
      end
    end
    task :update_mods => :environment do
      pid_list = ENV['pid_list']

      return unless pid_list
      jay_prefix = ENV['jay_mods_dir']
      manifest = Util::Jay.mods_manifest(File.join(jay_prefix, 'manifest.txt'))
      open(pid_list) do |blob|
        blob.each do |line|
          line.strip!
          o = ContentAggregator.find(line)
          if !o
            LOGGER.info("No object found for #{line}")
            next
          end
          unless o.relationships(:has_model).include? 'info:fedora/ldpd:ContentAggregator'
            LOGGER.info("object for #{line} was not a ContentAggregator")
            next
          end

          id = o.descMetadata.term_values(:identifier).select{|v| v =~ /columbia\.jay/}.first
          if id
            path = manifest[id]
            if path
              path = File.join(jay_prefix,path)
              unless o.datastreams['DC'].term_values(:dc_identifier).include? id
                o.datastreams['DC'].update_indexed_attributes([:dc_identifier]=>[id])
              end
              Util::Jay.update_if_changed!(o, path)
            else
              LOGGER.info("No jay mods found for #{o.pid}(#{id})")
              next
            end
          else
            LOGGER.info("No jay id found for #{o.pid}")
            next
          end
          LOGGER.info("updated #{o.pid}")
        end
      end
    end
  end
 end