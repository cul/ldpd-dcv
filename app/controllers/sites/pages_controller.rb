module Sites
	class PagesController < ApplicationController
		include Dcv::RestrictableController
		include Dcv::CdnHelper
		include Dcv::MarkdownRendering
		include Dcv::CatalogIncludes

		before_filter :load_subsite, only: [:index, :new, :create]
		before_filter :load_page, except: [:index, :new, :create]

		layout :subsite_layout

		def initialize(*args)
			super(*args)
			self._prefixes.unshift 'sites'
			self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
		end

		def set_view_path
			super
			self.prepend_view_path('app/views/' + self.subsite_layout)
		end

		def load_subsite(*pages)
			@subsite ||= begin
				site_slug = params[:site_slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				if pages.blank?
					Site.includes(:nav_links, :site_pages).find_by(slug: site_slug)
				else
					Site.includes(:nav_links, site_pages: [:site_text_blocks]).find_by(slug: site_slug, site_pages: { slug: pages })
				end
			end
		end

		def load_page(args = params)
			@page ||= begin
				load_subsite(args[:slug]).site_pages.where(slug: args[:slug]).first
			end
		end

		def show
			respond_to do |format|
				format.json { render json: @page.to_json }
				format.html { render action: 'page' }
			end
		end

		def edit
		end

		def subsite_config
			@subsite_config ||= load_subsite.to_subsite_config
		end

		def subsite_layout
			subsite_config['layout'] || 'catalog'
		end

		def subsite_styles
			palette = subsite_config['palette'] || 'monochromeDark'
			"#{subsite_layout}-#{palette}"
		end

		def catalog_uri
			SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
		end

		# Catalog, local, or subsite index as appropriate
		def search_action_url(options = {})
			if load_subsite.search_type == 'local'
				url_for(action: 'index', controller: "/#{load_subsite.slug}")
			else
				f = {}
				load_subsite.constraints.each do |search_scope, facet_value|
					next unless facet_value.present?
					facet_field = (search_scope == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
					f[facet_field] = Array(facet_value)
				end
				if load_subsite.restricted.present?
					repository_id = @document[:lib_repo_code_ssim].first
					search_repository_catalog_path(repository_id: repository_id, f: f)
				else
					# pages have a module scope so controller needs the leading slash
					# and since this is not a BL controller, we need to supply the search field
					url_for(action: 'index', controller: '/catalog', f: f, search_field: 'all_text_teim')
				end
			end
		end
	end
end
