require 'csv'
class Site < ActiveRecord::Base
	has_many :nav_links, dependent: :destroy
	has_many :site_pages, dependent: :destroy
	store :constraints, accessors: [ :publisher, :project, :collection ], coder: JSON, suffix: true

	def initialize(atts = {})
		super
		self.search_type ||= 'catalog'
	end

	def grouped_links
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

	def to_subsite_config
		config = {slug: slug, restricted: slug =~ /restricted/, palette: palette, layout: layout}
		config.with_indifferent_access
	end
end