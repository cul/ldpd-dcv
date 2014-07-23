require 'digest'
LOGGER = Logger.new(STDOUT)
def update_if_changed!(obj, path)
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

module ActiveFedora
  VERSION = '7.1.0'
end

namespace :util do
  namespace :jay do
  	task :update_mods => :environment do

      pid_list = ENV['pid_list']
      return unless pid_list
  	  manifest = {}
  	  jay_prefix = ENV['jay_mods_dir']
  	  open(File.join(jay_prefix, 'manifest.txt')) do |blob|
  	  	blob.each do|line|
          entry = line.strip
          id = entry.split('/')[-1].sub(/_mods\.xml$/,'')
          manifest[id] = entry
        end
  	  end
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
              update_if_changed!(o, path)
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