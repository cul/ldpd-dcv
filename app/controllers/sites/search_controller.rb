module Sites
	class SearchController < ApplicationController
		include Dcv::RestrictableController
		include Dcv::CdnHelper
		include Dcv::MarkdownRendering
		include Dcv::CatalogIncludes
		include Dcv::Sites::ConfiguredLayouts
		include Dcv::Sites::SearchableController
		include Dcv::MapDataController
		include Cul::Omniauth::AuthorizingController
		include ShowFieldDisplayFieldHelper

		before_action :load_subsite
		before_action :set_map_data_json, only: [:map_search]
		before_action :authorize_document, only: :show

		delegate :blacklight_config, to: :@subsite

		helper_method :extract_map_data_from_document_list

		layout :subsite_layout

		self.search_state_class = Dcv::Sites::SearchState

		def authorize_document(_document=nil)
			authorize_action_and_scope(Ability::ACCESS_SUBSITE, load_subsite)
		end

		def initialize(*args)
			super(*args)
			self._prefixes.unshift 'sites'
			self._prefixes.unshift '' # allow view_path to find action templates without 'sites' prefix first
		end

		# overrides the session role key from Cul::Omniauth::RemoteIpAbility
		def current_ability
			@current_ability ||= Ability.new(current_user, roles: session["cul.roles"], remote_ip: request.remote_ip)
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

		def subsite_key
			params[:site_slug] || load_subsite&.slug
		end

		def show
			params[:format] ||= 'html'
			if params[:id] =~ Dcv::Routes::DOI_ID_CONSTRAINT[:id]
				@response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=#{blacklight_config.document_unique_id_param} v=$#{blacklight_config.document_unique_id_param}}"
			else
				@response, @document = fetch "info:fedora/#{params[:id]}", q: "{!raw f=fedora_pid_uri_ssi v=$#{blacklight_config.document_unique_id_param}}"
			end

			respond_to do |format|
				format.html do
					setup_next_and_previous_documents if params[:id] =~ Dcv::Routes::DOI_ID_CONSTRAINT[:id]
					render 'show' # explicate since proxies action delegates here
				end

				format.json { render json: {response: {document: @document}}}

				# Add all dynamically added (such as by document extensions)
				# export formats.
				@document.export_formats.each_key do | format_name |
					format.send(format_name.to_sym) { render plain: @document.export_as(format_name), layout: false }
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
			site_search_url(load_subsite.slug, options.except(:controller, :action))
		end

		def tracking_method
			"site_track_path"
		end
	end
end
