class Api::SitePagesController < Api::BaseController
  # include Dcv::RestrictableController

  before_action :load_subsite, only: [:get_all_pages, :patch_multiple, :delete_multiple]
  before_action :load_page, only: [:delete]

  # GET /site/:site_slug/pages
  def get_all_pages
    authorize_action_and_scope Ability::MANAGE_SUBSITE, @subsite
    pages_json = @subsite.site_pages.map(&method(:site_page_json))
    render json: { pages: pages_json}
  end

  # PATCH /site/:site_slug/pages (for bulk updating of pages, e.g. from the general properties page which updates title and slug)
  # This method will compare the array in params and the @subsite.site_pages array, and delete any pages that were not included
  # in the request.
  def patch_multiple
    authorize_action_and_scope Ability::MANAGE_SUBSITE, @subsite
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

  # DELETE /site/:site_slug/pages/:page_slug
  def delete
    authorize_action_and_scope Ability::MANAGE_SUBSITE, @subsite
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

  private

    def load_subsite()
      @subsite ||= begin
        site_slug = params[:site_slug]
        site_ = Site.find_by(slug: site_slug)
        # site_slug = "restricted/#{site_slug}" if restricted? // TODO : handle restricted sites
        raise ActiveRecord::RecordNotFound unless site_
        site_
      end
    end

    def load_page()
      @page ||= begin
        SitePage.find_by(site_id: load_subsite.id, slug: params[:page_slug])
      end
      raise ActiveRecord::RecordNotFound unless @page
      @page
    end

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

    def site_page_json(site_page)
      {
        id: site_page.id,
        pageSlug: site_page.slug, # NOTE: we distinguish between pageSlug and siteSlug in the UI and in this API! But in the model, pageSlug is just a page record's 'slug' property (and siteSlug is not part of the record - site_id is used the foreign key)
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