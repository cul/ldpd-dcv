module Repositories
  class CatalogController < ::SubsitesController
    include Dcv::MapDataController

    before_action :set_map_data_json, only: [:map_search]

    configure_blacklight do |config|
      Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
      config.add_facet_field 'content_availability', label: 'Limit by Availability',
        query: {
          onsite: { label: 'Reading Room', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}!access_control_levels_ssim:Public*" },
          public: { label: 'Public', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}access_control_levels_ssim:Public*" },
        }
    end

    def initialize(*args)
      super(*args)
      self._prefixes.unshift 'repositories'
      self._prefixes.unshift 'repositories/catalog'
    end



    def search_service_context
      { builder: { addl_processor_chain: [:constrain_to_repository_context, :hide_concepts_when_query_blank_filter] } }
    end

    def set_view_path
      super
      self.prepend_view_path('app/views/repositories')
      self.prepend_view_path('app/views/repositories/catalog')
    end

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
      'dcv'
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
  end
end
