require 'csv'
class Site < ActiveRecord::Base
	include Dcv::Sites::Constants
	include Blacklight::Configurable
	has_many :nav_links, dependent: :destroy
	has_many :site_pages, dependent: :destroy
	store :constraints, accessors: [ :publisher, :project, :collection ], coder: JSON, suffix: true
	serialize :image_uris, Array

	validates :search_type, inclusion: { in: VALID_SEARCH_TYPES }

	configure_blacklight do |config|
		Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
	end

	def initialize(atts = {})
		super
		self.search_type ||= DEFAULT_SEARCH_TYPE
	end

	#TODO: this route will change for local searches
	def routing_params(args = {})
		args.reject { |k,v| k.to_s == 'slug' }.merge(controller: 'catalog')
	end

	def configure_blacklight!
		configure_blacklight do |config|
			config.default_solr_params[:fq] += default_fq()
			config.show.route = self.routing_params
			if self.search_type == 'local'
				config.document_unique_id_param = :ezid_doi_ssim
				config.show.route = ShowRouteFactory.new(self)
			else
				config.show.route = self.routing_params
			end
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
		f = {}
		self.constraints.each do |search_scope, facet_value|
			next unless facet_value.present?
			case search_scope
			when 'collection'
				facet_field = 'lib_collection_sim'
			when 'project'
				facet_field = 'lib_project_short_ssim'
			when 'publisher'
				facet_field = 'publisher_ssim'
			end
			next unless facet_field
			f[facet_field] = Array(facet_value)
		end
		if self.restricted.present?
			f['lib_repo_code_ssim'] = [self.repository_id]
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

    def nav_menus_attributes=(attributes)
    end

	# patch for Rails 4 store, which doesn't have suffixes
	def publisher_constraints=(constraints)
		self.publisher= Array(constraints)
	end

	# patch for Rails 4 store, which doesn't have suffixes
	def collection_constraints=(constraints)
		self.collection= Array(constraints)
	end

	# patch for Rails 4 store, which doesn't have suffixes
	def project_constraints=(constraints)
		self.project= Array(constraints)
	end

	def about_link
		nav_links.detect {|link| link.about_link? }
	end

	def to_subsite_config
		config = {slug: slug, restricted: slug =~ /restricted/, palette: palette, layout: layout}
		config.with_indifferent_access
	end
	class ShowRouteFactory
		def initialize(site)
			@slug = site.slug.split('/')[-1]
			@restricted = site.slug =~ /restricted/
		end
		def doi_params(doc)
			return {} unless doc
			doi_id = doc.fetch('ezid_doi_ssim',[]).first&.sub(/^doi:/,'')
			{ id: doi_id }
		end
		def merge opts = {}
			controller_name = "/sites/search"
			controller_name = "/restricted/#{controller_name}" if @restricted
			doc = opts[:id]
			doi_params(doc).merge(controller: controller_name, action: :show)
		end
	end
end