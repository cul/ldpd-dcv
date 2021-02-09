class MigrateSiteConstraintsToSearchConfiguration < ActiveRecord::Migration
	def up
		add_column :sites, :search_configuration, :text 
		Site.all.each do |site|
			site.search_configuration.scope_constraints = JSON.load(site.instance_variable_get(:@attributes)["constraints"].value)
			site.layout = 'custom' unless Site::VALID_LAYOUTS.include?(site.layout)
			config = SubsiteConfig.new(SubsiteConfig.for_path(site.slug, site.restricted))
			site.search_configuration.date_search_configuration = config.date_search_configuration
			site.search_configuration.map_configuration = config.map_configuration
			site.search_configuration.display_options = config.display_options
			site.save
		end
	end

	def down
		remove_column(:sites, :search_configuration)
	end
end
