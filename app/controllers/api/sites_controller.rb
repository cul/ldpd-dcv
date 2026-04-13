class Api::SitesController < Api::BaseController

  before_action :load_subsite, 
    only: [
      :get_site,
      :get_site_nav_groups,
      :update,
      :update_site_pages,
      :upload_signature_image,
      :delete_signature_images_watermark,
      :delete_signature_images_banner,
    ]

  # GET /api/v1/sites
  # Return a list of all subsites -- if the URL parameter
  def get_sites
    isEditor = params[:isEditor] == "true"
    if isEditor
      authorize_action_and_scope :edit, Site
      @sites = Site.all.select { |site| site[:editor_uids].include? current_user[:uid] }
    else
      authorize_action_and_scope :admin, Site
      @sites = Site.all
    end
    render json: { sites: @sites.each { |subsite| { id: subsite.id, title: subsite.title, slug: subsite.slug } } }
  end

  # GET /api/v1/sites/:site_slug
  def get_site
    authorize_site_update @subsite
    render json: { site: site_json(@subsite) }
  end

  # GET /api/v1/sites/:site_slug/nav_groups
  # Returns an array of nav group objects, each with an array of nested links
  # The returned representation differs from how nav_links are stored in the data base:
  #  - we extract the group number, group label, link order number, and link label
  #  - we create an ordered array of objects representing the groups
  #  - each group has an ordered array of links with the actual link data
  def get_site_nav_groups
    authorize_site_update @subsite

    return_data = []
    flat_nav_links_array = @subsite.nav_links.to_a
    flat_nav_links_array.each do |record|
      group_number, group_label = extract_prefix_and_label record[:sort_group]

      unless return_data[group_number]
        return_data[group_number] = {
          group_label: group_label,
          children_links: []
        }
      end

      link_number, link_label = extract_prefix_and_label record[:sort_label]
      unless return_data[group_number][link_number].nil?
        raise Error 'Two links in the same group have the same order number--this should not happen!'
      end
      return_data[group_number][:children_links][link_number] = {
        link_label: link_label,
        link_value: record[:link],
        external: record[:external],
        icon_class: record[:icon_class]
      }
    end

    render json: { navGroups: nav_groups_json(return_data) }
  end

  # POST /api/v1/sites/:site_slug/signature_images
  def upload_signature_images
    authorize_site_update @subsite
    banner_upload = params[:banner]
    watermark_upload = params[:watermark]
    if banner_upload
      BannerUploader.new(@subsite).store!(banner_upload)
      @subsite.touch
    end
    if watermark_upload
      WatermarkUploader.new(@subsite).store!(watermark_upload)
      @subsite.touch
    end
    render json: { site: site_json(@subsite) }
  rescue ActiveRecord::RecordInvalid, CarrierWave::IntegrityError => ex
    render json: { error: ex.message }, status: :unprocessable_entity
  end

  # DELETE /api/v1/sites/:site_slug/signature_images/watermark
  def delete_signature_images_watermark
    Rails.logger.debug "DELETING WATERMARK IMAGE FOR SITE #{@subsite}..."
    authorize_site_update @subsite
    if @subsite.has_watermark_image?
      FileUtils.rm_f(@subsite.watermark_uploader.store_path('signature.svg'))
    end
    render json: { site: site_json(@subsite) }
  end

  # DELETE /api/v1/sites/:site_slug/signature_images/banner
  def delete_signature_images_banner
    Rails.logger.debug "DELETING BANNER IMAGE FOR SITE #{@subsite.slug}..."
    authorize_site_update @subsite
    if @subsite.has_banner_image?
      FileUtils.rm_f(@subsite.banner_uploader.store_path('signature-banner.png'))
      @subsite.touch
    end
    render json: { site: site_json(@subsite) }
  end

  # PATCH /api/v1/sites/:site_slug
  # Mostly taken from SitesController#update
  def update
    Rails.logger.debug 'INSIDE API SITES CONTROLLER UPDATE ACTION'
    authorize_site_update @subsite
    # though Site accepts nested attributes of nav_links for persistence, we want to handle the updates
    # specially (to accommodate the deletion and reordering without recourse to record id)
    update_params = site_params
    nav_links_attributes = update_params.delete('nav_links_attributes')
    # TODO: we should not allow uploading images thru this endpoint, as they are not part of the site model
    banner_upload = update_params.delete('banner')
    watermark_upload = update_params.delete('watermark')
    # Rails.logger.debug 'BANNER' if banner_upload
    # Rails.logger.debug banner_upload if banner_upload
    # Rails.logger.debug 'WATERMARK' if watermark_upload
    # Rails.logger.debug watermark_upload if watermark_upload

    Rails.logger.debug "UPDATING SUBSITE..."
    Rails.logger.debug update_params.inspect

    @subsite.update! update_params
    Rails.logger.debug "UPDATED SUBSITE!"

    # TODO: refactor to delete all and then save all...
    if nav_links_attributes.present? || nav_links_attributes == []
      # Delete the nav links if the attribute is present but empty
      if nav_links_attributes == []
        @subsite.nav_links.destroy_all
      end
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
    end


    Rails.logger.debug 'uploading banner and watermark images if present....'
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
        Rails.logger.debug "SITE SLUG: #{site_slug}"
        # site_slug = "restricted/#{site_slug}" if restricted? # TODO : handle restricted sites
        s = Site.find_by(slug: site_slug)
        s.configure_blacklight! if s
        s
      end
    end

    def site_params
      unroll_nav_link_params
      params.require(:site).permit(:title, :slug, :palette, :layout, :show_facets, :alternative_title, :search_type, :editor_uids, :image_uris, :nav_links_attributes, :banner, :watermark,
                                   image_uris: [], nav_links_attributes: [:sort_group, :sort_label, :link, :external, :icon_class])
      .to_h.tap do |p|
        p['image_uris']&.delete_if { |v| v.blank? }
      end
    end

    # Captures the numbered prefix and label for a group_label or sort_label with
    # the format "<2 digit number>:<label text>"
    # Returns an array:
    #   return_value[0] : the prefix as an integer
    #   return_value[1] : the label as a string
    def extract_prefix_and_label(string)
      if string =~ /^(\d+)\s*:\s*(.*)$/
        return [$1.to_i, $2]
      else
        raise ArgumentError, "this group or link label has the wrong formatting: #{string}"
      end
    end

    # This method takes a nested nav_groups object and 'flattens' it into an array
    # of objects that correspond to the shape of our ActiveRecord nav_links model
    def unroll_nav_link_params
      nav_groups = params['site'].delete('nav_groups')
      return unless nav_groups
      flat_nav_links_array = []
      nav_groups.each_with_index do |group_data, group_index|
        sort_group = "#{sprintf("%02d", group_index)}:#{group_data['group_label']}"
        group_data['children_links'].each_with_index do |link_data, link_index|
          sort_label = "#{sprintf("%02d", link_index)}:#{link_data['link_label']}"
          flat_nav_links_array << {
            sort_group: sort_group,
            sort_label: sort_label,
            link: link_data['link_value'],
            external: link_data['external'],
            icon_class: link_data['icon_class']
          }
        end
      end
      params['site']['nav_links_attributes'] = flat_nav_links_array
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
        # We need to append the updated_at value to the image URLs, in order to bust the HTTP cache for those assets
        bannerImageUrl: site.has_banner_image? ? "#{site.banner_url}?v=#{site.updated_at.to_i}" : view_context.asset_path("signature/signature-banner.png"),
        watermarkImageUrl: site.has_watermark_image? ? "#{site.watermark_url}?v=#{site.updated_at.to_i}" : view_context.asset_path("signature/signature.svg"),
        hasBannerImage: site.has_banner_image?,
        hasWatermarkImage: site.has_watermark_image?,
        updatedAt: site.updated_at,
      }
    end

    # snake_case to camelCase for nav_groups array of hashes
    def nav_groups_json(nav_groups)
      nav_groups.map do |group|
        {
          groupLabel: group[:group_label],
          childrenLinks: group[:children_links].map do |link|
            {
              linkLabel: link[:link_label],
              linkValue: link[:link_value],
              external: link[:external],
              iconClass: link[:icon_class]
            }
          end
        }
      end
    end
end