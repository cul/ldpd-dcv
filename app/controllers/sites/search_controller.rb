module Sites
	class SearchController < ApplicationController
		include Dcv::RestrictableController
		include Dcv::CdnHelper
		include Dcv::MarkdownRendering
		include Dcv::CatalogIncludes
		include Dcv::Sites::ConfiguredLayouts
		include Dcv::Sites::SearchableController
		include Cul::Omniauth::AuthorizingController
		include ShowFieldDisplayFieldHelper

		before_filter :load_subsite

		delegate :blacklight_config, to: :@subsite

		layout :subsite_layout

		def authorize_document(_document=nil)
			authorize_action_and_scope(Ability::ACCESS_SUBSITE, @subsite)
		end

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

		def load_subsite
			@subsite ||= begin
				site_slug = params[:site_slug] || params[:slug]
				site_slug = "restricted/#{site_slug}" if restricted?
				s = Site.includes(:nav_links).find_by(slug: site_slug)
				s&.configure_blacklight!
				s
			end
		end

		def show
			params[:format] ||= 'html'
			@response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=#{blacklight_config.document_unique_id_param} v=$#{blacklight_config.document_unique_id_param}}"
			return unless authorize_document

			respond_to do |format|
				format.html do
					setup_next_and_previous_documents
					render 'show' # explicate since proxies action delegates here
				end

				format.json { render json: {response: {document: @document}}}

				# Add all dynamically added (such as by document extensions)
				# export formats.
				@document.export_formats.each_key do | format_name |
					format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
				end
			end
		end

		def index
			super
		end

		def subsite_config
			@subsite_config ||= load_subsite.to_subsite_config
		end

		def catalog_uri
			SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
		end

		def search_action_url(options = {})
			site_search_url(options.except(:controller, :action).merge(site_slug: load_subsite.slug))
		end

		def tracking_method
			"site_track_path"
		end
	end
end
