class AddEditorUidsToSites < ActiveRecord::Migration[4.2]
  def change
  	add_column :sites, :editor_uids, :text 
  end
end
