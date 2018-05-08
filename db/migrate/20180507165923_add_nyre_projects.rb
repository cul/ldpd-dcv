class AddNyreProjects < ActiveRecord::Migration
  def change
  	create_table :nyre_projects do |table|
  		table.string :call_number
  		table.string :name
  		table.index :call_number
  	end
  end
end
