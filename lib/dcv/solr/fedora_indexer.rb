require "active-fedora"

module Dcv::Solr::FedoraIndexer

  NUM_FEDORA_RETRY_ATTEMPTS = 3
  DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS = 5.seconds
  DEFAULT_INDEX_OPTS = {
    skip_generic_resources: false, verbose_output: false, softcommit: true, reraise: false
  }.freeze
  def self.descend_from(pid, pids_to_omit=nil, verbose_output=false)
    if pid.blank?
      raise 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
    end

    begin

      unless ActiveFedora::Base.exists?(pid)
        raise 'Could not find Fedora object with pid: ' + pid
      end

      if pids_to_omit.present? && pids_to_omit.include?(pid)
        puts 'Skipping topmost object in this set (' + pid + ') because it has been intentionally omitted...' if verbose_output
      else
        puts 'Indexing topmost object in this set (' + pid + ')...' if verbose_output
        puts 'If this is a BagAggregator with a lot of members, this may take a while...' if verbose_output

        yield pid

      end

      puts 'Recursively retreieving and indexing all members of ' + pid + '...'

      unique_pids = Cul::Hydra::RisearchMembers.get_recursive_member_pids(pid, true)

      total_number_of_members = unique_pids.length
      puts 'Recursive search found ' + total_number_of_members.to_s + ' members.' if verbose_output

      if pids_to_omit.present?
        unique_pids = unique_pids - pids_to_omit
        total_number_of_members = unique_pids.length
        puts 'After checking against the list of omitted pids, the total number of objects to index will be: ' + total_number_of_members.to_s if verbose_output
      end

      i = 1
      if total_number_of_members > 0
        unique_pids.each {|pid|

          puts 'Recursing on ' + i.to_s + ' of ' + total_number_of_members.to_s + ' members (' + pid + ')...' if verbose_output

          yield pid

          i += 1
        }
      end

    rescue RestClient::Unauthorized => e
      error_message = "Skipping #{pid} due to error: " + e.message + '.  Problem with Fedora object?'
      puts error_message
      logger.error error_message if defined?(logger)
    end

    puts 'Recursion complete!'

  end
  def self.recursively_index_fedora_objects(top_pid, pids_to_omit=nil, skip_generic_resources=false, verbose_output=false)

    index_opts = { skip_generic_resources: skip_generic_resources, verbose_output: verbose_output }
    descend_from(top_pid, pids_to_omit, verbose_output) do |pid|
      self.index_pid(pid, index_opts)
    end
  end

  # this is a compatibility method for bridging the previously used postional arguments to
  # keyword arguments by extracting an opts hash from varargs
  # legacy positional opts signature: skip_resources = false, verbose_output = false, softcommit = true
  # keyword defaults are in DEFAULT_INDEX_OPTS
  # @param args [Array] a list of arguments ending with an options hash
  # @return options hash
  def self.extract_index_opts(args)
    args = args.dup # do not modify the original list
    # extract opts hash
    index_opts = (args.last.is_a? Hash) ? args.pop : {}
    # symbolize keys and reverse merge defaults
    index_opts = index_opts.map {|k,v| [k.to_sym, v] }.to_h
    index_opts = DEFAULT_INDEX_OPTS.merge(index_opts)
    # assign any legacy positional arguments, permitting explicit nils
    unless args.empty?
      index_opts[:skip_generic_resources] = args[0] if args.length > 0
      index_opts[:verbose_output] = args[1] if args.length > 1
      index_opts[:softcommit] = args[2] if args.length > 2
    end
    index_opts
  end

  # @return SolrDocument
  def self.index_pid(pid, *args)
    # We found an object with the desired PID. Let's reindex it
    index_opts = extract_index_opts(args)
    begin
      active_fedora_object = nil

      NUM_FEDORA_RETRY_ATTEMPTS.times do |i|
        begin
          active_fedora_object = ActiveFedora::Base.find(pid, cast: false)
          if index_opts[:skip_generic_resources] && Dcv::Solr::DocumentAdapter::ActiveFedora.matches_any_cmodel?(active_fedora_object, ['info:fedora/ldpd:GenericResource'])
            Rails.logger.warn 'Object was skipped because GenericResources are being skipped and it is a GenericResource.'
            break
          else
            doc_adapter = Dcv::Solr::DocumentAdapter::ActiveFedora(active_fedora_object)
            # rsolr params are camelcased
            rsolr_params = index_opts[:softcommit] ? {softCommit: true} : {}
            solr_docs = doc_adapter.update_index(rsolr_params)
            solr_doc = SolrDocument.new(solr_docs.first&.to_h)
            if Dcv::Sites::Import::Solr.exists?(solr_doc)
              Dcv::Sites::Import::Solr.new(solr_doc).run
            end
            puts 'done.' if index_opts[:verbose_output]
            return solr_doc
          end
        rescue RestClient::RequestTimeout, Errno::EHOSTUNREACH => e
          remaining_attempts = (NUM_FEDORA_RETRY_ATTEMPTS-1) - i
          if remaining_attempts == 0
            raise
          else
            Rails.logger.error "Error: Could not connect to fedora. (#{e.class.to_s + ': ' + e.message}).  Will retry #{remaining_attempts} more #{remaining_attempts == 1 ? 'time' : 'times'} (after a #{DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS} second delay)."
            sleep DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS
          end
        rescue RuntimeError => e
          if e.message.index('Circular dependency detected while autoloading')
            # The RuntimeError 'Circular dependency detected while autoloading CLASSNAME' comes up when
            # we're doing multithreaded indexing. Waiting a few seconds for the class to autoload and then
            # retrying seems to help with this.
            sleep 5
          else
            # Other RuntimeErrors should be passed on
            raise
          end
        end
      end
    rescue SystemExit, Interrupt => e
      # Allow system interrupt (ctrl+c)
      raise
    rescue Exception => e
      puts "Encountered problem with #{pid}.  Skipping record.  Exception class: #{e.class.name}.  Message: #{e.message}"
      if index_opts[:reraise]
        raise
      end
    end
  end
end