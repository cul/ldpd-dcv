class AddSitePageImageCaption < ActiveRecord::Migration[6.1]
  def change
    reversible do |direction|
      change_table :site_page_images do |table|
        direction.up   do
          rename_column :site_page_images, :doi, :image_identifier
          table.string :alt_text
          table.string :caption
        end
        direction.down do
          rename_column :site_page_images, :image_identifier, :doi
          table.remove :alt_text
          table.remove :caption
        end
      end
    end
  end
end
