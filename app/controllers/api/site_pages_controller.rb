class Api::SitePagesController < Api::BaseController
  # include Dcv::RestrictableController
  # include Dcv::CdnHelper
  # include Dcv::MarkdownRendering
  # include Dcv::CatalogIncludes
  # include Dcv::Sites::ConfiguredLayouts
  # include Cul::Omniauth::AuthorizingController

  # before_action :load_subsite, only: [:index, :new, :create, :show]
  before_action :load_subsite, only: [:get_all_pages, :patch_multiple, :delete_multiple]
  before_action :load_page, only: [:delete]
  # before_action :load_page, except: [:index, :new, :create]
  # before_action :authorize_site_update, except: [:index, :show]

  delegate :blacklight_config, to: :@subsite

  layout :request_layout

  rescue_from ActiveRecord::RecordNotFound, with: :on_page_not_found

  def initialize(*args)
    super(*args)
    self._prefixes.unshift 'sites'
    self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
  end

  def load_subsite()
    @subsite ||= begin
      site_slug = params[:site_slug]
      site_ = Site.find_by(slug: site_slug)
      # site_slug = "restricted/#{site_slug}" if restricted? // TODO : handle restricted sites
      raise ActiveRecord::RecordNotFound unless site_
      site_
    end
  end

  # Changed
  def load_page()
    @page ||= begin
      SitePage.find_by(site_id: load_subsite.id, slug: params[:page_slug])
    end
    raise ActiveRecord::RecordNotFound unless @page
    @page
  end

  # def subsite_key
  #   load_subsite.slug
  # end

  # def request_layout
  #   if (@subsite && action_name == 'show')
  #     subsite_layout
  #   else
  #     'sites'
  #   end
  # end

  # GET /site/:site_slug/pages
  def get_all_pages
    authorize_action_and_scope :update, @subsite
    pages_json = @subsite.site_pages.map(&method(:site_page_json))
    render json: { pages: pages_json}
  end

  # def show
  #   raise ActiveRecord::RecordNotFound unless @page

  #   respond_to do |format|
  #     format.json { render json: @page.to_json }
  #     format.html { render action: 'page' }
  #   end
  # end

  # def edit
  # end

  # PATCH /site/:site_slug/pages (for bulk updating of pages, e.g. from the general properties page which updates title and slug)
  # This method will compare the array in params and the @subsite.site_pages array, and delete any pages that were not included
  # in the request.
  def patch_multiple
    authorize_action_and_scope(:update, @subsite)
    current_pages_slugs = @subsite.site_pages.map { |page| page[:slug] } 
    new_pages_slugs = multiple_pages_params.map { |page| page[:slug]}
    site_id = @subsite.id

    current_pages_slugs.each do |existing_page_slug|
      existing_page = SitePage.find_by(site_id: site_id, slug: existing_page_slug)

      if new_pages_slugs.include? existing_page_slug
        new_page_data = multiple_pages_params.select { |pp| pp[:slug] == existing_page_slug }.pop
        # update only if the title has changed
        existing_page.update!(title: new_page_data['title']) if new_page_data['title'] != existing_page[:title]
      else
        # delete pages not included in the request body
        existing_page.destroy!
      end
    end

    render json: { message: 'Pages updated successfully' }
  rescue ActiveRecord::RecordInvalid => ex
    render json: { error: ex.message }, status: :unprocessable_entity
  end

  # TODO : remove --- we will allow deletion of multiple in patch
  # DELETE /site/:site_slug/pages (for bulk deleting of pages, e.g. from the general properties page)
  def delete_multiple
    authorize_action_and_scope(:update, @subsite)
    Rails.logger.debug "params;"
    Rails.logger.debug multiple_pages_params
    multiple_pages_params.each do |page_params|
      page = SitePage.find_by(site_id: @subsite.id, slug: page_params[:page_slug])
      next unless page
      if page.slug == 'home'
        render json: { error: 'The homepage cannot be deleted' }, status: :forbidden
        return
      end
      page.destroy
    end
  end

  # DELETE /site/:site_slug/pages/:page_slug
  def delete
    if @page.slug == 'home'
      render json: { error: 'The homepage cannot be deleted' }, status: :forbidden
      return
    end
    @page.destroy
    render json: { message: 'Page deleted successfully' }
  rescue  ActiveRecord::RecordNotFound => ex
    render json: { error: 'Page not found' }, status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => ex
    render json: { error: ex.message }, status: :unprocessable_entity
  end

  # def update
  #   begin
  #     load_page.update!(page_params)
  #     flash[:notice] = "Page Updated!"
  #     redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: @page.slug)
  #   rescue ActiveRecord::RecordInvalid => ex
  #     flash[:alert] = ex.message
  #     redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: params[:slug])
  #   end
  # end

  # def new
  #   @page = load_subsite.site_pages.new
  # end

  # def create
  #   begin
  #     create_params = page_params
  #     # separate the text blocks, since page must exist for them to be saved
  #     site_text_blocks_attributes = create_params.delete(:site_text_blocks_attributes)
  #     @page = load_subsite.site_pages.create!(create_params)
  #     @page.update(site_text_blocks_attributes: site_text_blocks_attributes) if site_text_blocks_attributes.present?
  #     flash[:notice] = "Page Created!"
  #     redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: @page.slug)
  #   rescue ActiveRecord::RecordInvalid => ex
  #     flash[:alert] = ex.message
  #     redirect_to new_site_page_path(site_slug: @subsite.slug)
  #   end
  # end

  # def subsite_config
  #   @subsite_config ||= load_subsite&.to_subsite_config
  # end

  # def catalog_uri
  #   SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
  # end

  # Catalog, local, or subsite index as appropriate
  # def search_action_url(options = {})
  #   if load_subsite.search_type == 'custom'
  #     url_params = options.merge(action: 'index', controller: load_subsite.slug)
  #   elsif load_subsite.search_type == 'local'
  #     url_params = options.clone
  #     if load_subsite.restricted.present?
  #       url_params.merge!(controller: 'restricted/sites/search', action: 'index', site_slug: load_subsite.slug)
  #     else
  #       url_params.merge!(controller: 'sites/search', action: 'index', site_slug: load_subsite.slug)
  #     end
  #   else
  #     # delegate to relevant catalog with pre-selected filters
  #     # initialize with facet values if present
  #     f = options.fetch('f', {}).merge(load_subsite.default_filters)
  #     if load_subsite.restricted.present?
  #       repository_id = @document[:lib_repo_code_ssim].first
  #       return search_repository_search_path(repository_id: repository_id, f: f)
  #     else
  #       # pages have a module scope so controller needs the leading slash
  #       # and since this is not a BL controller, we need to supply the search field
  #       url_params = { action: 'index', controller: '/catalog', f: f, search_field: 'all_text_teim' }
  #     end
  #   end
  #   url_for(url_params)
  # end

  # def on_page_not_found
  #   redirect_url = asset_redirect(params[:slug], params[:format]) if params[:site_slug] == 'assets'
  #   if redirect_url
  #     redirect_to(redirect_url)
  #     return
  #   end

  #   render(status: :not_found, plain: "Page Not Found")
  # end

  private
    # Users can update multiple pages' titles at once from the general properties page
    def multiple_pages_params
      params.require(:pages).map do |page_params|
        page_params.permit(:page_slug, :site_slug, :id, :title, :updated_at)
        .to_h.tap do |p|
          p[:slug] = p.delete(:page_slug) # remap page_slug param to just slug to match the SitePage model schema
          p.delete(:site_slug) # remove site_slug as it is not part of the site page model (site_id is used instead)
        end
      end
    end

    def page_params
      params.require(:site_page)
        .permit(
          :page_slug, :title, :use_multiple_columns,
          site_page_images_attributes: [:id, :alt_text, :caption, :image_identifier, :_destroy],
          site_text_blocks_attributes: [:id, :label, :markdown, :_destroy, { site_page_images_attributes: [:id, :alt_text, :caption, :image_identifier, :style, :_destroy]}]
        ).to_h.tap do |p|
          p[:slug] = p.delete(:page_slug) # remap page_slug param to just slug to match the SitePage model schema
          p[:columns] = (p.delete(:use_multiple_columns).to_s == 'true') ? 2 : 1
          p[:site_page_images_attributes]&.delete_if {|ix, obj| obj[:id].blank? && obj[:image_identifier].blank? }
          p[:site_text_blocks_attributes]&.each do |ix, tbp|
            tbp[:site_page_images_attributes]&.delete_if {|ix, obj| obj[:id].blank? && obj[:image_identifier].blank? }
          end
        end
    end

    # def asset_redirect(file_basename, file_ext)
    #   file_ext = file_ext.downcase
    #   asset_name = "#{file_basename.sub(/-[a-f0-9]{64}$/, '')}.#{file_ext}"
    #   helpers.asset_url(asset_name)
    # rescue Sprockets::Rails::Helper::AssetNotFound
    #   nil
    # end

    def site_page_json(site_page)
      {
        id: site_page.id,
        pageSlug: site_page.slug, # NOTE: we distinguish between pageSlug and siteSlug in the UI and in this API! But in the model, pageSlug is just a page record's 'slug' property (and siteSlug is not part of the record)
        title: site_page.title,
        columns: site_page.columns,
        updatedAt: site_page.updated_at,
        sitePageImages: site_page.site_page_images.map do |image|
          {
            id: image.id,
            imageIdentifier: image.image_identifier,
            style: image.style,
            altText: image.alt_text,
            caption: image.caption
          }
        end,
        siteTextBlocks: site_page.site_text_blocks.map do |text_block|
          {
            id: text_block.id,
            label: text_block.sort_label,
            markdown: text_block.markdown,
            sitePageImages: text_block.site_page_images.map do |image|
              {
                id: image.id,
                imageIdentifier: image.image_identifier,
                style: image.style,
                altText: image.alt_text,
                caption: image.caption
              }
            end
          }
        end
      }
    end
end