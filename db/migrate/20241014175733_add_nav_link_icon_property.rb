class AddNavLinkIconProperty < ActiveRecord::Migration[6.1]
  def change
    add_column :nav_links, :icon_class, :string , null: true
  end
end
