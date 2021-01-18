module Nyre
  class ProjectsController < ApplicationController
    include Dcv::CatalogIncludes

    before_filter :set_view_path
    helper_method :extract_map_data_from_document_list, :url_for_document

    layout 'nyre'

    def self.subsite_key
      'nyre'
    end

    def self.subsite_config
      @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(subsite_key, false)
    end

    def subsite_config
      @subsite_config ||=  self.class.subsite_config
    end

    def self.load_subsite
      @subsite ||= Site.find_by(slug: subsite_key)
    end

    def load_subsite
      @subsite ||= self.class.load_subsite
    end

    def subsite_key
      self.class.subsite_key
    end

    def subsite_layout
      self.class.subsite_key
    end

    def self.configure_blacklight_scope_constraints(config, exclude_by_id = false)
      publishers = Array(subsite_config.dig('scope_constraints','publisher')).compact
      config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
      # Do not include the publish target itself or any additional publish targets defined in search results
      if exclude_by_id
        config.default_solr_params[:fq] << '-id:("' + publishers.map{|info_fedora_prefixed_pid| info_fedora_prefixed_pid.gsub('info:fedora/', '') }.join('" OR "') + '")'
      end
    end

    configure_blacklight do |config|
      Dcv::Configurators::NyreBlacklightConfigurator.configure(config)
      config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_street', :symbol), :label => 'Address', :sort => 'index', :limit => 10
      # Include this target's content in search results, and any additional publish targets specified in subsites.yml
      configure_blacklight_scope_constraints(config)
    end

    def subsite_config
      return self.class.subsite_config
    end

    # haaaaaaack to not reproduce templates
    def initialize(*args)
      super(*args)
      self._prefixes << 'nyre/projects' 
      self._prefixes << 'nyre'
      self._prefixes << '/catalog'
      self._prefixes.unshift "shared"
      self._prefixes.unshift ""
    end

    def set_view_path
      self.prepend_view_path('app/views/shared')
      self.prepend_view_path('app/views/nyre')
      self.prepend_view_path('nyre')
      self.prepend_view_path('app/views/nyre/projects')
      self.prepend_view_path('nyre/projects')
      self.prepend_view_path('app/views/' + controller_path)
      self.prepend_view_path(controller_path)
    end

    def resource
      id_param = (params[:id] =~ /^\d+$/) ? :id : :call_number
      @resource ||= OpenStruct.new Nyre::Project.find_by(id_param => params[:id]).attributes
    end

    def show
      if params[:format].to_s == 'rss'
        render nothing: true, status: :not_found
        return
      end
      # build an original path term prefix from project call number
      call_number_prefix = "ldpd_#{resource.call_number.gsub('.','_')}_*"
      # look for matching records in this project, eg original_name_tesim:ldpd_YR_0948_MH_*
      q = "original_name_tesim:#{call_number_prefix}"
      join_param = "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}"
      (@response, @document_list) = search_results(q: join_param + q)
      @response["facet_counts"].fetch("facet_fields", {}).tap do |facets|
        facets.each do |facet_name, facet_values|
          if facet_name == 'subject_hierarchical_geographic_street_ssim'
            resource.street_addresses = facet_values.select { |val| val.is_a? String }
          end
          if facet_name == 'subject_hierarchical_geographic_borough_ssim'
            resource.neighborhoods = facet_values.select { |val| val.is_a? String }
          end
          resource.borough = facet_values[0] if facet_name == "subject_hierarchical_geographic_borough_ssim"
          resource.architect = facet_values[0] if facet_name == "role_architect_ssim"
          resource.owner_agent = facet_values[0] if facet_name == "role_owner_agent_ssim"
        end
      end
      resource.street_addresses ||= []
      resource.neighborhoods ||= []
    end

    def search_action_url(*args)
      search_nyre_url *args
    end

    # Override to point to NYRE controller
    def url_for_document doc, options = {}
      if respond_to?(:blacklight_config) and
          blacklight_config.show.route and
          (!doc.respond_to?(:to_model) or doc.to_model.is_a? SolrDocument)
        route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)
        route[:controller] = "/nyre"
        route
      else
        doc
      end
    end

    def tracking_method
      "track_nyre_path"
    end

    # copied from Dcv::Sites::SearchableController
    def extract_map_data_from_document_list(document_list)

      # We want this data to be as compact as possible because we're sending a lot to the client

      max_title_length = 50

      map_data = []
      document_list.each do |document|
        if document['geo'].present?
          document['geo'].each do |coordinates|

            lat_and_long = coordinates.split(',')

            is_book = document['lib_format_ssm'].present? && document['lib_format_ssm'].include?('books')

            title = document['title_display_ssm'][0].gsub(/\s+/, ' ') # Compress multiple spaces and new lines into one
            title = title[0,max_title_length].strip + '...' if title.length > max_title_length

            row = {
              id: document.id,
              c: lat_and_long[0].strip + ',' + lat_and_long[1].strip,
              t: title,
              b: is_book ? 'y' : 'n',
            }

            map_data << row
          end
        end
      end

      return map_data
    end
  end
end