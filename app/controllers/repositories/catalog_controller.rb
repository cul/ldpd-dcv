module Repositories
  class CatalogController < ::SubsitesController
    include Dcv::MapDataController
    include Dcv::Sites::ReadingRooms

    before_action :set_map_data_json, only: [:map_search]

    configure_blacklight do |config|
      Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
      config.search_state_fields << :repository_id # allow repository id for routing
      config.add_facet_field 'content_availability', label: 'Limit by Availability',
        query: {
          onsite: { label: 'Reading Room', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}!access_control_levels_ssim:Public*" },
          public: { label: 'Public', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}access_control_levels_ssim:Public*" },
        }
      Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config, search_bar: Dcv::SearchBar::RepositoriesComponent)

    end

    def initialize(*args)
      super(*args)
      self._prefixes.unshift 'repositories'
      self._prefixes.unshift 'repositories/catalog'
    end



    def search_service_context
      { builder: { addl_processor_chain: [:constrain_to_repository_context, :hide_concepts_when_query_blank_filter] } }
    end

    prepend_view_path('app/views/repositories')
    prepend_view_path('app/views/repositories/catalog')

    # SubsiteController Overrides
    def self.subsite_config
      {}
    end

    def subsite_config
      return self.class.subsite_config
    end

    def default_search_mode
      subsite_config.fetch('default_search_mode',:grid)
    end

    def default_search_mode_cookie
      cookie_name = "#{params[:repository_id]}_search_mode".to_sym
      cookie = cookies[cookie_name]
      unless cookie
        cookies[cookie_name] = default_search_mode.to_sym
      end
    end

    def subsite_key
      key = params[:repository_id].dup
      key.downcase!
      key.gsub!('-','')
      key
    end

    def subsite_layout
      'gallery'
    end

    def subsite_styles
      ["#{subsite_layout}-#{Dcv::Sites::Constants.default_palette}", "catalog"]
    end

    def index
      if request.format.csv?
        stream_csv_response_for_search_results
      else
        super
      end
    end

    def about
    end

    def aboutcollection
    end

    def show_digital_project?
      true
    end
    helper_method :show_digital_project?
  end
end
