class AddSitePageImages < ActiveRecord::Migration[6.1]
  def change
    create_table :site_page_images do |t|
      t.string :doi, null: false
      t.string :style, null: false, default: "hero"
    end
    add_belongs_to :site_page_images, :depictable, polymorphic: true
  end
end
