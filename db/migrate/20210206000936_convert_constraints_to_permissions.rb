class ConvertConstraintsToPermissions < ActiveRecord::Migration
	def up
		rename_column :sites, :constraints, :permissions 
		Site.all.each do |site|
			config = SubsiteConfig.new(SubsiteConfig.for_path(site.slug, site.restricted))
			site.permissions = config.site_permissions
			site.save
		end
	end

	def down
		rename_column :sites, :permissions, :constraints
		Site.all.each do |site|
			site.permissions = {}
			site.save
		end
	end
end