class Api::SitesController < Api::BaseController

  before_action :load_subsite, only: [:show, :update]

  # GET /api/v1/sites
  # Return a list of all subsites
  def index
    authorize_action_and_scope :admin, Site
    @sites = Site.all
    render json: { sites: @sites.each { |subsite| { id: subsite.id, title: subsite.title, slug: subsite.slug } } }
  end

  # GET /api/v1/sites/:site_slug
  def show
    render json: { site: site_json(@subsite) }
  end

  # PATCH /api/v1/sites/:site_slug
  # Mostly taken from SitesController#update
  def update
    Rails.logger.debug 'INSIDE API SITES CONTROLLER UPDATE ACTION'
    authorize_action_and_scope(:update, @subsite)
    site_attributes = site_params
    # though Site accepts nested attributes of nav_links for persistence, we want to handle the updates
    # specially (to accommodate the deletion and reordering without recourse to record id)
    nav_links_attributes = site_attributes.delete('nav_links_attributes')
    banner_upload = params[:site].delete(:banner)
    watermark_upload = params[:site].delete(:watermark)

    Rails.logger.debug "UPDATING SUBSITE..."
    Rails.logger.debug site_attributes.inspect
    @subsite.update! site_attributes
    Rails.logger.debug "UPDATED SUBSITE!"
    if nav_links_attributes.present?
      @subsite.nav_links.each do |nav_link|
        if nav_links_attributes.present?
          # update this available link record
          nav_link.update! nav_links_attributes.shift
        else
          # out of attributes so delete remaining nav links
          nav_link.destroy
        end
      end
      # remaining attributes represent new nav links that must be added
      nav_links_attributes.each do |nav_link_attributes|
        @subsite.nav_links.create!(nav_link_attributes)
      end
    else
      @subsite.nav_links.destroy_all
    end


    BannerUploader.new(@subsite).store!(banner_upload) && @subsite.touch if banner_upload
    WatermarkUploader.new(@subsite).store!(watermark_upload) && @subsite.touch if watermark_upload

    # TODO : handle restricted sites
    # if restricted?
    #   redirect_to edit_restricted_site_path(slug: @subsite.slug.sub('restricted/', ''))
    # else
    #   redirect_to edit_site_path(slug: @subsite.slug)
    # end
    Rails.logger.debug "FINISHED WITH UPDATE! SENDING JSON RESPONSE..."
    Rails.logger.debug @subsite.inspect
    render json: { site: site_json(@subsite) }
  rescue ActiveRecord::RecordInvalid, CarrierWave::IntegrityError => ex
    Rails.logger.debug 'RESCUED FROM ERROR!'
    render json: { error: ex.message }, status: :unprocessable_entity
  end

  private
    def load_subsite
      @subsite ||= begin
        site_slug = params[:site_slug] || params[:slug]
        # site_slug = "restricted/#{site_slug}" if restricted? # TODO : handle restricted sites
        s = Site.find_by(slug: site_slug)
        s.configure_blacklight! if s
        s
      end
    end

    def unroll_nav_link_params
      nav_menus_attributes = params['site'].delete('nav_menus_attributes')
      return unless nav_menus_attributes
      nav_links = []
      nav_menus_attributes.each do |group_index, group_data|
        sort_group = "#{sprintf("%02d", group_index.to_i)}:#{group_data['label']}"
        group_data.fetch('links_attributes', {}).each do |link_index, link_data|
          sort_label = "#{sprintf("%02d", link_index.to_i)}:#{link_data['label']}"
          nav_links << {sort_group: sort_group, sort_label: sort_label, link: link_data['link'], external: link_data['external'], icon_class: link_data['icon_class']}
        end
      end
      params['site']['nav_links_attributes'] = nav_links
    end

    def site_params
      unroll_nav_link_params
      params.require(:site).permit(:title, :slug, :palette, :layout, :show_facets, :alternative_title, :search_type, :editor_uids, :image_uris, :nav_links_attributes,
                                   image_uris: [], nav_links_attributes: [:sort_group, :sort_label, :link, :external, :icon_class])
      .to_h.tap do |p|
        p.delete('banner')
        p.delete('watermark')
        p['image_uris']&.delete_if { |v| v.blank? }
      end
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
    # Converts ruby snake_case attributes to javascript camelCase
    def site_json(site)
      {
        id: site.id,
        title: site.title,
        slug: site.slug,
        persistentUrl: site.persistent_url,
        publisherUri: site.publisher_uri,
        imageUris: site.image_uris,
        repositoryId: site.repository_id,
        layout: site.layout,
        palette: site.palette,
        searchType: site.search_type,
        restricted: site.restricted,
        permissions: site.permissions,
        mapSearch: site.map_search,
        dateSearch: site.date_search,
        alternativeTitle: site.alternative_title,
        showFacets: site.show_facets,
        searchConfiguration: site.search_configuration,
      }
    end
end