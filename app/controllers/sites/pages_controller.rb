module Sites
	class PagesController < ApplicationController
		include Dcv::RestrictableController
		include Dcv::CdnHelper
		include Dcv::MarkdownRendering
		include Dcv::CatalogIncludes
		include Dcv::Sites::ConfiguredLayouts
		include Cul::Omniauth::AuthorizingController

		before_action :load_subsite, only: [:index, :new, :create, :show]
		before_action :load_page, except: [:index, :new, :create]
		before_action :authorize_site_update, except: [:index, :show]

		delegate :blacklight_config, to: :@subsite

		layout :request_layout

		rescue_from ActiveRecord::RecordNotFound, with: :on_page_not_found

		def initialize(*args)
			super(*args)
			self._prefixes.unshift 'sites'
			self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
		end

		def set_view_path
			super
			self.prepend_view_path('app/views/shared')
			self.prepend_view_path('app/views/' + self.subsite_layout) if load_subsite && subsite_layout
			self.prepend_view_path('app/views/' + controller_path.sub(/^restricted/,'')) if self.restricted?
			self.prepend_view_path('app/views/' + controller_path)
		end

		def load_subsite(*pages)
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				if pages.blank?
					site_ = Site.find_by(slug: site_slug)
				else
					site_ = Site.includes(:site_pages).find_by(slug: site_slug, site_pages: { slug: pages })
				end
				raise ActiveRecord::RecordNotFound unless site_
				site_&.configure_blacklight!
				site_
			end
		end

		def load_page(args = params)
			@page ||= begin
				load_subsite.site_pages.where(slug: args[:slug]).first if load_subsite(args[:slug])
			end
			raise ActiveRecord::RecordNotFound unless @page
			@page
		end

		def subsite_key
			load_subsite.slug
		end

		def request_layout
			if (@subsite && action_name == 'show')
				subsite_layout
			else
				'sites'
			end
		end

		def show
			raise ActiveRecord::RecordNotFound unless @page

			respond_to do |format|
				format.json { render json: @page.to_json }
				format.html { render action: 'page' }
			end
		end

		def edit
		end

		def update
			begin
				load_page.update!(page_params)
				flash[:notice] = "Page Updated!"
				redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: @page.slug)
			rescue ActiveRecord::RecordInvalid => ex
				flash[:alert] = ex.message
				redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: params[:slug])
			end
		end

		def new
			@page = load_subsite.site_pages.new
		end

		def create
			begin
				create_params = page_params
				# separate the text blocks, since page must exist for them to be saved
				site_text_blocks_attributes = create_params.delete(:site_text_blocks_attributes)
				@page = load_subsite.site_pages.create!(create_params)
				@page.update(site_text_blocks_attributes: site_text_blocks_attributes) if site_text_blocks_attributes.present?
				flash[:notice] = "Page Created!"
				redirect_to edit_site_page_path(site_slug: @subsite.slug, slug: @page.slug)
			rescue ActiveRecord::RecordInvalid => ex
				flash[:alert] = ex.message
				redirect_to new_site_page_path(site_slug: @subsite.slug)
			end
		end

		def destroy
			if params[:slug].to_s == 'home'
				flash[:alert] = "home page cannot be deleted"
			else
				@page.destroy
				flash[:notice] = "page at #{params[:slug]} has been deleted."
			end
			redirect_to edit_site_path(slug: @subsite.slug)
		end

		def subsite_config
			@subsite_config ||= load_subsite&.to_subsite_config
		end

		def catalog_uri
			SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
		end

		# Catalog, local, or subsite index as appropriate
		def search_action_url(options = {})
			if load_subsite.search_type == 'custom'
				url_params = options.merge(action: 'index', controller: load_subsite.slug)
			elsif load_subsite.search_type == 'local'
				url_params = options.clone
				if load_subsite.restricted.present?
					url_params.merge!(controller: 'restricted/sites/search', action: 'index', site_slug: load_subsite.slug)
				else
					url_params.merge!(controller: 'sites/search', action: 'index', site_slug: load_subsite.slug)
				end
			else
				# delegate to relevant catalog with pre-selected filters
				# initialize with facet values if present
				f = options.fetch('f', {}).merge(load_subsite.default_filters)
				if load_subsite.restricted.present?
					repository_id = @document[:lib_repo_code_ssim].first
					return search_repository_catalog_path(repository_id: repository_id, f: f)
				else
					# pages have a module scope so controller needs the leading slash
					# and since this is not a BL controller, we need to supply the search field
					url_params = { action: 'index', controller: '/catalog', f: f, search_field: 'all_text_teim' }
				end
			end
			url_for(url_params)
		end

		def on_page_not_found
			redirect_url = asset_redirect(params[:slug], params[:format]) if params[:site_slug] == 'assets'
			if redirect_url
				redirect_to(redirect_url)
				return
			end

			render(status: :not_found, plain: "Page Not Found")
		end

		private
			def page_params
				params.require(:site_page)
					.permit(
						:slug, :title, :use_multiple_columns,
						site_page_images_attributes: [:id, :alt_text, :caption, :image_identifier, :_destroy],
						site_text_blocks_attributes: [:id, :label, :markdown, :_destroy, { site_page_images_attributes: [:id, :alt_text, :caption, :image_identifier, :style, :_destroy]}]
					).to_h.tap do |p|
						p[:columns] = (p.delete(:use_multiple_columns).to_s == 'true') ? 2 : 1
						p[:site_page_images_attributes]&.delete_if {|ix, obj| obj[:id].blank? && obj[:image_identifier].blank? }
						p[:site_text_blocks_attributes]&.each do |ix, tbp|
							tbp[:site_page_images_attributes]&.delete_if {|ix, obj| obj[:id].blank? && obj[:image_identifier].blank? }
						end
					end
			end

			def asset_redirect(file_basename, file_ext)
				file_ext = file_ext.downcase
				asset_name = "#{file_basename.sub(/-[a-f0-9]{64}$/, '')}.#{file_ext}"
				helpers.asset_url(asset_name)
			rescue Sprockets::Rails::Helper::AssetNotFound
				nil
			end
	end
end
