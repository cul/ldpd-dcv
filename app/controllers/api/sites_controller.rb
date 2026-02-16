class Api::SitesController < Api::BaseController

  # GET /api/v1/sites
  # Return a list of all subsites
  def index
    authorize_action_and_scope :admin, Site
    @sites = Site.all
    render json: { sites: @sites.each { |site| { id: site.id, title: site.title, slug: site.slug } } }
  end

  # Get /api/v1/sites/:site_slug
  def show
    @site = Site.find_by_slug(params[:site_slug])
  end

  private

    def sites_params
      params.ensure!
    end

  # create_table "sites", force: :cascade do |t|
  #   t.string "slug", null: false
  #   t.string "title"
  #   t.string "persistent_url"
  #   t.string "publisher_uri"
  #   t.text "image_uris"
  #   t.string "repository_id"
  #   t.string "layout"
  #   t.string "palette"
  #   t.string "search_type"
  #   t.boolean "restricted"
  #   t.text "permissions"
  #   t.text "map_search"
  #   t.text "date_search"
  #   t.datetime "created_at"
  #   t.datetime "updated_at"
  #   t.string "alternative_title"
  #   t.boolean "show_facets", default: false
  #   t.text "editor_uids"
  #   t.text "search_configuration"
  #   t.index ["slug"], name: "index_sites_on_slug", unique: true
  # end
    def site_json(user)
      {
        id: site.id,
        title: site.title,
        slug: site.slug,
        persistent_url: site.persistent_url,
        publisher_uri: site.publisher_uri,
        image_uris: site.image_uris,
        repository_id: site.repository_id,
        layout: site.layout,
        palette: site.palette,
        search_type: site.search_type,
        restricted: site.restricted,
        permissions: site.permissions,
        map_search: site.map_search,
        date_search: site.date_search,
        alternative_title: site.alternative_title,
        show_facets: site.show_facets,
        search_configuration: site.search_configuration,
      }
    end
end