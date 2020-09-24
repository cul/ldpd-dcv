module Nyre
  class ProjectsController < ApplicationController
    include Dcv::CatalogIncludes

    before_filter :set_view_path
    helper_method :extract_map_data_from_document_list, :url_for_document

    layout Proc.new { |controller|
      subsite_config['layout']
    }

    def self.subsite_config
      return SUBSITES['public'].fetch('nyre',{})
    end

    def subsite_key
      'nyre'
    end

    def subsite_layout
      SUBSITES['public']['nyre']['layout']
    end

    configure_blacklight do |config|
      Dcv::Configurators::NyreBlacklightConfigurator.configure(config)
      config.add_facet_field ActiveFedora::SolrService.solr_name('subject_hierarchical_geographic_street', :symbol), :label => 'Address', :sort => 'index', :limit => 10
      # Include this target's content in search results, and any additional publish targets specified in subsites.yml
      publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
      config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
      config.default_solr_params[:fq] << '-active_fedora_model_ssi:GenericResource'
    end

    def subsite_config
      return self.class.subsite_config
    end

    # haaaaaaack to not reproduce templates
    def initialize(*args)
      super(*args)
      self._prefixes << subsite_config['layout'] + '/projects' 
      self._prefixes << subsite_config['layout']
      self._prefixes << '/catalog'
    end

    def set_view_path
      self.prepend_view_path('app/views/catalog')
      self.prepend_view_path('app/views/' + self.subsite_layout)
      self.prepend_view_path(self.subsite_layout)
      self.prepend_view_path('app/views/' + self.subsite_layout + '/projects')
      self.prepend_view_path(self.subsite_layout + '/projects')
      self.prepend_view_path('app/views/' + controller_path)
      self.prepend_view_path(controller_path)
    end

    def resource
      id_param = (params[:id] =~ /^\d+$/) ? :id : :call_number
      @resource ||= OpenStruct.new Nyre::Project.find_by(id_param => params[:id]).attributes
    end

    def show
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

    # copied from subsites, why is it private?
    private

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