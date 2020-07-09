class ChangeSiteImageToSiteImages < ActiveRecord::Migration
  def up
    change_column :sites, :image_uri, :text
	rename_column :sites, :image_uri, :image_uris
  end

  def down
	rename_column :sites, :image_uris, :image_uri
    change_column :sites, :image_uri, :string
  end
end
