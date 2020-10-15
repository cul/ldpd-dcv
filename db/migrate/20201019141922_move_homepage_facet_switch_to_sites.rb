class MoveHomepageFacetSwitchToSites < ActiveRecord::Migration
	def up
		add_column :sites, :show_facets, :boolean, default: false
		SitePage.where(slug: 'home') do |p|
			s = p.site
			s.show_facets = p.show_facets ? true : false # column had no default previously
			s.save
		end
		remove_column :site_pages, :show_facets, :boolean
	end

	def down
		add_column :site_pages, :show_facets, :boolean, default: false
		SitePage.where(slug: 'home').all do |p|
			s = p.site
			p.show_facets = s.show_facets
			p.save
		end
		remove_column :sites, :show_facets, :boolean
	end
end
