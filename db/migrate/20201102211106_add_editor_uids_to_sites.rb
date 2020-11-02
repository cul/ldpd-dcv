class AddEditorUidsToSites < ActiveRecord::Migration
  def change
  	add_column :sites, :editor_uids, :text 
  end
end
