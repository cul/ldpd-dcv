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

		rescue_from ActiveRecord::RecordNotFound, with: :on_page_not_found

		before_action :load_subsite!
		before_action :set_map_data_json, only: [:map_search]
		before_action :store_unless_user, except: [:update, :destroy, :api_info]
		before_action :redirect_unless_local, only: :index
		before_action :authorize_document, only: :show
		before_action :meta_nofollow!, only: [:index, :map_search]
		before_action :meta_noindex!, only: [:index, :map_search]

		delegate :blacklight_config, to: :@subsite

		helper_method :extract_map_data_from_document_list

		layout :subsite_layout

		self.search_service_class = Dcv::SearchService
		self.search_state_class = Dcv::Sites::LocalSearchState

		def authorize_document(_document=nil)
			authorize_action_and_scope(Ability::ACCESS_SUBSITE, load_subsite)
		end

		def search_url_service
			@search_url_service ||= Dcv::Sites::SearchUrlService.new
		end

		def redirect_unless_local
			unless load_subsite.search_type == Site::SEARCH_LOCAL || load_subsite.search_type == Site::SEARCH_REPOSITORIES
				redirect_to search_url_service.search_action_url(load_subsite, self, {})
			end
		end

		def search_service_context
			{ builder: { addl_processor_chain: params[:action] == 'index' ? [] : [:remove_cmodel_filters] } }
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
			prepend_view_path('app/views/' + self.subsite_layout)
			custom_layout = load_subsite.slug.sub('%2F', '/') if load_subsite&.slug
			prepend_view_path('app/views/' + custom_layout) if custom_layout
			prepend_view_path(custom_layout)
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

		def load_subsite!
			_subsite = load_subsite
			return _subsite if _subsite
			raise ActiveRecord::RecordNotFound
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

			unless @document
				render file: 'public/404.html', layout: false, status: 404
				return
			end
			respond_to do |format|
				format.html do
					@search_context = (setup_next_and_previous_documents || {}) if params[:id] =~ Dcv::Routes::DOI_ID_CONSTRAINT[:id]
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

		def synchronizer
			params[:format] ||= 'html'
			if params[:id] =~ Dcv::Routes::DOI_ID_CONSTRAINT[:id]
				@response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=#{blacklight_config.document_unique_id_param} v=$#{blacklight_config.document_unique_id_param}}"
			else
				@response, @document = fetch "info:fedora/#{params[:id]}", q: "{!raw f=fedora_pid_uri_ssi v=$#{blacklight_config.document_unique_id_param}}"
			end

			unless @document
				render file: 'public/404.html', layout: false, status: 404
				return
			end
			authorize_document
			render layout: 'minimal', locals: { document: @document }
		end

		def legacy_redirect
			unless params[:document_id]
				render status: :bad_request, plain: 'document_id param is required'
			end
			legacy_id ||= params[:document_id].dup
			@response, @document = fetch legacy_id, q: "{!raw f=identifier_ssim v=$#{blacklight_config.document_unique_id_param}}"

			if @document.blank?
				render status: :not_found, plain: "no document with id #{params[:document_id]}"
				return
			end
			document_id = Array(@document[blacklight_config.document_unique_id_param] || @document[:id]).first
			document_id = document_id&.sub("doi:", "")
			if load_subsite.search_type == 'local'
				redirect_to action: "show", id: document_id
			else
				redirect_to controller: 'catalog', action: 'show', id: @document[:id]
			end
		end

		def subsite_config
			@subsite_config ||= (load_subsite&.to_subsite_config || {})
		end

		def catalog_uri
			SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
		end

		def search_action_url(options = {})
			site_search_url(load_subsite.slug, options.except(:controller, :action))
		end

		def search_action_path(options = {})
			site_search_url(load_subsite.slug, options.except(:controller, :action))
		end

		def tracking_method
			"site_track_path"
		end
	end
end
