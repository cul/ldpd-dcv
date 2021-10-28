module Sites
	class PagesController < ApplicationController
		include Dcv::RestrictableController
		include Dcv::CdnHelper
		include Dcv::MarkdownRendering
		include Dcv::CatalogIncludes
		include Dcv::Sites::ConfiguredLayouts
		include Cul::Omniauth::AuthorizingController

		before_action :load_subsite, only: [:index, :new, :create]
		before_action :load_page, except: [:index, :new, :create]
		before_action :authorize_site_update, except: [:index, :show]

		layout :request_layout

		def initialize(*args)
			super(*args)
			self._prefixes.unshift 'sites'
			self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
		end

		def set_view_path
			super
			self.prepend_view_path('app/views/shared')
			self.prepend_view_path('app/views/' + self.subsite_layout)
			self.prepend_view_path('app/views/' + controller_path.sub(/^restricted/,'')) if self.restricted?
			self.prepend_view_path('app/views/' + controller_path)
		end

		def load_subsite(*pages)
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				if pages.blank?
					Site.find_by(slug: site_slug)
				else
					Site.includes(:site_pages).find_by(slug: site_slug, site_pages: { slug: pages })
				end
			end
		end

		def load_page(args = params)
			@page ||= begin
				load_subsite.site_pages.where(slug: args[:slug]).first if load_subsite(args[:slug])
			end
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
			unless @page
				render status: :not_found, file: "#{Rails.root}/public/404.html", layout: false
				return
			end
			respond_to do |format|
				format.json { render json: @page.to_json }
				format.html { render action: 'page' }
			end
		end

		def edit
		end

		def update
			begin
				load_page.update_attributes!(page_params)
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
				@page.update_attributes(site_text_blocks_attributes: site_text_blocks_attributes) if site_text_blocks_attributes.present?
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

		private
			def page_params
				params.require(:site_page)
					.permit(:slug, :title, :use_multiple_columns, site_text_blocks_attributes: [:label, :markdown])
					.to_h.tap do |p|
						p[:columns] = (p.delete(:use_multiple_columns).to_s == 'true') ? 2 : 1
					end
			end
	end
end
