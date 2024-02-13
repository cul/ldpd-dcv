module Nyre
  class ProjectsController < ApplicationController
    include Dcv::CatalogIncludes
    include Dcv::MapDataController
    include Dcv::Sites::SearchableController
    include Dcv::Sites::ConfiguredLayouts

    before_action :set_view_path, :load_subsite
    helper_method :extract_map_data_from_document_list, :url_for_document

    layout 'signature'

    prepend_view_path('app/views/nyre')

    def self.subsite_key
      'nyre'
    end

    def self.subsite_config
      @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(subsite_key, false)
    end

    def subsite_config
      @subsite_config ||= load_subsite&.to_subsite_config || SubsiteConfig.for_path(subsite_key, false)
    end

    def self.load_subsite
      @subsite ||= Site.find_by(slug: subsite_key)
    end

    def load_subsite
      @subsite ||= Site.find_by(slug: subsite_key)
    end

    def subsite_key
      self.class.subsite_key
    end

    def subsite_layout
      'signature'
    end

    def subsite_palette
      'blue'
    end

    def signature_image_path
      nil
    end

    def signature_banner_image_path
      view_context.asset_path("nyre/nyre-collage.png")
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
      config.add_facet_field 'subject_hierarchical_geographic_street_ssim', :label => 'Address', :sort => 'index', :limit => 10
      # Include this target's content in search results, and any additional publish targets specified in subsites.yml
      configure_blacklight_scope_constraints(config)
      config.show.route.merge!(controller: "/nyre")
    end

    def subsite_config
      return self.class.subsite_config
    end

    # haaaaaaack to not reproduce templates
    def initialize(*args)
      super(*args)
      self._prefixes << "#{subsite_key}/projects"
      self._prefixes << subsite_key
      self._prefixes << subsite_layout
      self._prefixes << '/catalog'
      self._prefixes.unshift "shared"
      self._prefixes.unshift ""
    end

    def set_view_path
      self.prepend_view_path('app/views/shared')
      self.prepend_view_path("app/views/#{subsite_key}")
      self.prepend_view_path(subsite_key)
      self.prepend_view_path('app/views/' + controller_path)
      self.prepend_view_path(controller_path)
      self.prepend_view_path("app/views/#{subsite_layout}")
    end

    def resource
      id_param = (params[:id] =~ /^\d+$/) ? :id : :call_number
      @resource ||= begin
        _project = Nyre::Project.find_by(id_param => params[:id])
        OpenStruct.new(_project.attributes) if _project
      end
    end

    def show
      if params[:format].to_s == 'rss'
        render nothing: true, status: :not_found
        return
      end

      unless resource
        render file: 'public/404.html', layout: false, status: 404
        return
      end
      # build an original path term prefix from project call number
      call_number_prefix = "ldpd_#{resource.call_number.gsub('.','_')}_*"
      # look for matching records in this project, eg original_name_tesim:ldpd_YR_0948_MH_*
      q = "original_name_tesim:#{call_number_prefix}"
      join_param = "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}"
      (@response, @document_list) = search_results(search_state.to_h) { |builder| builder.merge(q: join_param + q, defType: 'lucene') }
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

    def url_for_document doc, options = {}
      search_state.url_for_document(doc, options)
    end

    def tracking_method
      "track_nyre_path"
    end
  end
end