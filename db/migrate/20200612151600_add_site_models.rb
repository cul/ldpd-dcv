class AddSiteModels < ActiveRecord::Migration[4.2]
  def change
    create_table :sites do |t|
      t.string :slug, null: false
      t.string :title
      t.string :persistent_url
      t.string :publisher_uri
      t.string :image_uri
      t.string :repository_id
      t.string :layout
      t.string :palette
      t.string :search_type
      t.boolean :restricted
      t.text :constraints
      t.text :map_search
      t.text :date_search
      t.timestamps

      t.index :slug, unique: true
    end

    create_table :site_pages do |t|
      t.string :slug, null: false
      t.string :title
      t.integer :columns, default: 1, null: false
      t.boolean :show_facets
    end
    add_reference :site_pages, :site, foreign_key: true
    add_index :site_pages, [:site_id, :slug], unique: true

    create_table :site_text_blocks do |t|
      t.string :sort_label
      t.text :markdown
    end
    add_reference :site_text_blocks, :site_page, foreign_key: true

    create_table :nav_links do |t|
      t.string :sort_label
      t.string :sort_group
      t.string :link
      t.boolean :external
      t.timestamps
    end
    add_reference :nav_links, :site, foreign_key: true
  end
end
