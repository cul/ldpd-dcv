require 'csv'
class Site < ApplicationRecord
	include Dcv::Sites::Constants
	include Blacklight::Configurable
	include SolrDocument::CleanResolver
	has_many :scope_filters, as: :scopeable
	has_many :nav_links, dependent: :destroy, inverse_of: :site
	has_many :site_pages, dependent: :destroy
	accepts_nested_attributes_for :nav_links
	accepts_nested_attributes_for :scope_filters
	attribute :search_configuration, :site_search_configuration, default: -> {Site::SearchConfiguration.new}
	attribute :permissions, :site_permissions, default: -> {Site::Permissions.new}
	serialize :editor_uids, Array
	serialize :image_uris, Array

	validates :search_type, inclusion: { in: VALID_SEARCH_TYPES }
	validates :layout, inclusion: { in: VALID_LAYOUTS }
	validates_with DelegatingValidator, fields: [:search_configuration]

	configure_blacklight do |config|
		Dcv::Configurators::DcvBlacklightConfigurator.configure_default_solr_params(config)

		Dcv::Configurators::DcvBlacklightConfigurator.default_paging_configuration(config)

		# solr field configuration for search results/index views
		Dcv::Configurators::DcvBlacklightConfigurator.default_index_configuration(config)

		Dcv::Configurators::DcvBlacklightConfigurator.default_show_configuration(config)

		Dcv::Configurators::DcvBlacklightConfigurator.configure_index_fields(config)

		Dcv::Configurators::DcvBlacklightConfigurator.configure_show_fields(config)
		field_name = 'lib_repo_short_ssim'
		config.show_fields[field_name].link_to_facet = false
		field_name = 'lib_project_full_ssim'
		config.show_fields[field_name].link_to_facet = false

		Dcv::Configurators::DcvBlacklightConfigurator.configure_citation_fields(config)
		Dcv::Configurators::DcvBlacklightConfigurator.configure_sort_fields(config)
	end

	def initialize(atts = {})
		super
		@search_configuration ||= Site::SearchConfiguration.new(atts&.fetch('search_configuration', {}) || {})
		@permissions ||= Site::Permissions.new(atts&.fetch('permissions', {}) || {})
		self.search_type ||= DEFAULT_SEARCH_TYPE
	end

	def routing_params(args = {})
		if self.search_type == SEARCH_LOCAL
			args.reject { |k,v| k.to_s == 'slug' }.merge(controller: '/sites/search', site_slug: self.slug)
		else
			search_controller_path = (self.search_type == SEARCH_CATALOG) ? '/catalog': "/#{self.slug}"
			args.reject { |k,v| k.to_s == 'slug' }.merge(controller: search_controller_path)
		end
	end

	def self.configure_blacklight_search_local(config, search_configuration:, **_args)
		config.document_unique_id_param = :ezid_doi_ssim
		config.document_pagination_params[:fl] = "id,#{config.document_unique_id_param},format"
		config.search_state_class = Dcv::Sites::LocalSearchState
		Dcv::Configurators::DcvBlacklightConfigurator.default_faceting_configuration(config, geo: search_configuration.map_configuration.enabled)
		if search_configuration.facets.present?
			search_configuration.facets.each do |facet|
				facet.configure(config)
			end
		else
			Dcv::Configurators::DcvBlacklightConfigurator.configure_facet_fields(config)
		end
		if search_configuration.search_fields.present?
			search_configuration.search_fields.each do |search_field|
				search_field.configure(config)
			end
		else
			Dcv::Configurators::DcvBlacklightConfigurator.configure_keyword_search_field(config)
		end
		Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config)
		config
	end

	def self.configure_blacklight_search_repositories(config, search_configuration:, **_args)
		config.document_unique_id_param = :ezid_doi_ssim
		config.document_pagination_params[:fl] = "id,#{config.document_unique_id_param},format"
		config.search_state_class = Dcv::SearchState
		Dcv::Configurators::DcvBlacklightConfigurator.default_faceting_configuration(config, geo: search_configuration.map_configuration.enabled)
		if search_configuration.facets.present?
			search_configuration.facets.each do |facet|
				facet.configure(config)
			end
		else
			Dcv::Configurators::DcvBlacklightConfigurator.configure_facet_fields(config)
		end
		config.add_facet_field('content_availability',
			label: 'Limit by Availability',
			query: {
				onsite: { label: 'Reading Room', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}!access_control_levels_ssim:Public*" },
				public: { label: 'Public', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}access_control_levels_ssim:Public*" },
			}
		)
		if search_configuration.search_fields.present?
			search_configuration.search_fields.each do |search_field|
				search_field.configure(config)
			end
		else
			Dcv::Configurators::DcvBlacklightConfigurator.configure_keyword_search_field(config)
		end
		Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config, search_bar: Dcv::SearchBar::RepositoriesComponent)
		config.search_state_fields << :repository_id # allow repository id for routing
		config
	end

	def self.configure_csv_results(config, search_configuration:)
		# the Proc (if configured) is run via instnace_exec in controller
		if search_configuration.display_options.show_csv_results
			config.index.respond_to.csv = Proc.new { stream_csv_response_for_search_results }
		end
	end

	def self.configure_site_blacklight(config, default_fq:, routing_params:, search_configuration:, search_type:)
		config.default_solr_params[:fq] += default_fq
		config.show.route = routing_params
		config.track_search_session = search_type != SEARCH_CATALOG
		if search_type == SEARCH_LOCAL
			configure_blacklight_search_local(config, search_configuration: search_configuration)
			configure_csv_results(config, search_configuration: search_configuration)
		elsif search_type == SEARCH_REPOSITORIES
			configure_blacklight_search_repositories(config, search_configuration: search_configuration)
			configure_csv_results(config, search_configuration: search_configuration)
		else
			Dcv::Configurators::DcvBlacklightConfigurator.configure_facet_fields(config)
			Dcv::Configurators::DcvBlacklightConfigurator.configure_keyword_search_field(config)
			Dcv::Configurators::DcvBlacklightConfigurator.default_component_configuration(config)
			config
		end
	end

	def configure_blacklight!
		configure_blacklight do |config|
			Site.configure_site_blacklight(config, default_fq: default_fq, routing_params: routing_params, search_configuration: search_configuration, search_type: search_type)
		end
	end

	def configure_blacklight(*args, &block)
		blacklight_config.configure(*args, &block)
	end

	def image_uri(refresh = false)
		return image_uris.first if image_uris.length < 2
		@image_uri_memo = nil if refresh
		@image_uri_memo ||= image_uris.sample
	end

	def default_filters
		f = scope_filters.inject({}) do |result, filter|
			(result[filter.solr_field] ||= []) << filter.value if filter.solr_field
			result
		end
		if self.restricted.present? && self.repository_id
			f['lib_repo_code_ssim'] ||= [self.repository_id]
		end
		f
	end

	def default_fq
		default_filters().map do |f,v|
			v = v.map {|v| "\"#{v}\""}.join(" OR ")
			"#{f}:(#{v})"
		end
	end

	def nav_menus
		sorted_links = nav_links.sort { |a,b| (a.sort_group == b.sort_group) ? a.sort_label.to_s <=> b.sort_label.to_s : a.sort_group.to_s <=> b.sort_group.to_s }
		grouped_links = []
		sorted_links.each do |link|
			if grouped_links.empty? || grouped_links[-1]&.sort_label != link.sort_group
				grouped_links << NavMenu.new(link.sort_group)
			end
			grouped_links[-1].links << link
		end
		grouped_links
	end

	# this setter is necessary for the form builder
	def nav_menus_attributes=(attributes)
	end

	def constraints
		scope_filters.inject({}) {|result, filter| (result[filter.filter_type] ||= []) << filter.value; result }
	end

	def publisher_constraints
		scope_filters.select {|f| f.filter_type == 'publisher'}.map(&:value)
	end

	def collection_constraints
		scope_filters.select {|f| f.filter_type == 'collection'}.map(&:value)
	end

	def collection_key_constraints
		scope_filters.select {|f| f.filter_type == 'collection_key'}.map(&:value)
	end

	def project_constraints
		scope_filters.select {|f| f.filter_type == 'project'}.map(&:value)
	end

	def project_key_constraints
		scope_filters.select {|f| f.filter_type == 'project_key'}.map(&:value)
	end

	def about_link
		nav_links.detect {|link| link.about_link? }
	end

	def banner_uploader
		@banner_uploader ||= BannerUploader.new(self)
	end

	def has_banner_image?
		File.exists?(banner_uploader.store_path)
	end

	def banner_url
		banner_uploader.store_path.sub(File.join(Rails.root, 'public'), '')
	end

	def watermark_uploader
		@watermark_uploader ||= WatermarkUploader.new(self)
	end

	def has_watermark_image?
		File.exists?(watermark_uploader.store_path)
	end

	def watermark_url
		watermark_uploader.store_path.sub(File.join(Rails.root, 'public'), '')
	end

	# scrub CUL resolvers for format, or pass through
    def persistent_url
    	clean_resolver(super)
    end

	def to_subsite_config
		config = {
			'slug' => slug, 'restricted' => (slug =~ /restricted/).present?, 'palette' => palette, 'layout' => layout, 'scope_constraints' => constraints
		}.reverse_merge(permissions.attributes)
		SubsiteConfig.for_path(slug, slug =~ /restricted/).merge(config).merge(search_configuration.as_json).with_indifferent_access
	end

	def attributes
		super.tap do |atts|
			atts.delete('constraints')
			atts['search_configuration'] = @search_configuration.as_json
			atts['permissions'] = @permissions.as_json
		end
	end

	def include?(solr_doc)
		!default_filters.detect { |entry| (Array(solr_doc[entry[0]]) & entry[1]).blank? }
	end
end