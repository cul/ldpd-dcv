class AddAlternativeTitleToSite < ActiveRecord::Migration[4.2]
  def change
    reversible do |direction|
      change_table :sites do |table|
        direction.up   { table.string :alternative_title }
        direction.down { table.remove :alternative_title }
      end
    end
  end
end
