class Dcv::Solr::DocumentAdapter::ActiveFedora
  module RepresentativeGenericResourceBehavior
    # Return a representative file resource for the object
    # @param force_use_of_non_pid_identifier [Boolean] switch to require use of application id in struct map parsing
    # @return [GenericResource] a representative file resource
    # This method generally shouldn't be called with any parameters (unless we're doing testing)
    def get_representative_generic_resource(force_use_of_non_pid_identifier=false)
      return obj if test_cmodels(["info:fedora/ldpd:GenericResource"])

      # if there's an explicit assignment of representative image, return it
      assigned_image = get_singular_relationship_value(:schema_image)
      return ActiveFedora::Base.find(assigned_image.split('/')[-1]) if assigned_image

      return nil unless self.is_a?(Cul::Hydra::Models::Aggregator) # Only Aggregators have struct metadata
      # If we're here, then the object was not a Generic resource.
      # Try to get child info from a structMat datastream, and fall back to
      # the first :cul_member_of child if a structMap isn't present

      # Check for the presence of a structMap and get first GenericResource in that structMap
      if has_struct_metadata?
        begin
          struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(self.datastreams['structMetadata'].content)
        rescue Rubydora::FedoraInvalidRequest => e
          Rails.logger.error "Error: Problem accessing struct datastream data in #{self.pid}" # More specific error notice
          raise e
        end
        ng_div = struct.first_ordered_content_div #Nokogiri node response
        found_struct_div = ng_div.present?
      else
        found_struct_div = false
      end

      if found_struct_div
        return resource_from_structMetadata(ng_div, force_use_of_non_pid_identifier)
      else
        # If there isn't a structMap, just get the first child
        return resource_from_risearch
      end
    rescue ActiveFedora::ObjectNotFoundError
      Rails.logger.warn "#{get_singular_relationship_value(:schema_image)} not found in repository for #{obj.pid}"
      return nil
    end

    def resource_from_assignment
      assigned_value = get_singular_relationship_value(:schema_image)
      return ActiveFedora::Base.find(assigned_image.split('/')[-1]) if assigned_image
    end

    def resource_from_risearch
        member_pids = Cul::Hydra::RisearchMembers.get_direct_member_pids(self.pid, true)
        Rails.logger.warn "Warning: #{self.pid} is a member of itself!" if member_pids.include?(self.pid)
        if member_pids.first
          child_obj = ActiveFedora::Base.find(member_pids.first)
          return child_obj.get_representative_generic_resource
        else
          #Rails.logger.error "No child objects or resources for #{self.pid}"
          return nil
        end
    end

    def resource_from_structMetadata(ng_div, force_use_of_non_pid_identifier=false)
      content_ids = ng_div.attr('CONTENTIDS').split(' ') # Get all space-delimited content ids
      child_obj = nil

      # Try to do a PID lookup first
      unless force_use_of_non_pid_identifier
        content_ids.each do |content_id|
          next unless content_id.match(/^([A-Za-z0-9]|-|\.)+:(([A-Za-z0-9])|-|\.|~|_|(%[0-9A-F]{2}))+$/) # Don't do a lookup on identifiers that can't possibly be valid PID (otherwise we'd encounter an error)
          child_obj ||= ActiveFedora::Base.exists?(content_id) ? ActiveFedora::Base.find(content_id) : nil
        end
      end

      # Then fall back to identifier lookup
      if child_obj.nil?
        child_pid = nil
        content_ids.each do |content_id|
          child_pid ||= Cul::Hydra::RisearchMembers.get_pid_for_identifier(content_id)
          if force_use_of_non_pid_identifier && child_pid && content_id == child_pid
            # This really only runs when we're doing testing, if we want to specifically ensure that we're searching by a non-pid identifier
            child_pid = nil
          end
        end
        if child_pid
          child_obj = ActiveFedora::Base.find(child_pid, cast: false)
        end
      end

      if child_obj
        # Recursion!  Woo!
        return self.class.new(child_obj).get_representative_generic_resource(force_use_of_non_pid_identifier)
      else
        #Rails.logger.error "No object for dc:identifier in #{content_ids.inspect}"
        return nil
      end
    end
  end
end
