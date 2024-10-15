module Repositories
  class CatalogController < Sites::SearchController
    include Dcv::MapDataController
    include Dcv::Sites::ReadingRooms

    before_action :set_map_data_json, only: [:map_search]

    delegate :blacklight_config, to: :@subsite

    def initialize(*args)
      super(*args)
      self._prefixes.unshift 'repositories'
      self._prefixes.unshift 'repositories/catalog'
    end

    before_action :load_subsite!

    def search_service_context
      { builder: { addl_processor_chain: [:constrain_to_repository_context, :hide_concepts_when_query_blank_filter] } }
    end

    prepend_view_path('app/views/repositories')
    prepend_view_path('app/views/repositories/catalog')

    def load_subsite
      @subsite ||= begin
        site_slug = params[:repository_id]
        s = Site.includes(:nav_links).find_by(slug: site_slug)
        s&.configure_blacklight!
        s
      end
    end

    def subsite_key
      params[:repository_id] || load_subsite&.slug
    end

    alias_method :site_slug, :subsite_key

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

    def tracking_method
      "track_#{controller_name}_path"
    end
  end
end
