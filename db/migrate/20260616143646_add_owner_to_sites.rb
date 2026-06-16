class AddOwnerToSites < ActiveRecord::Migration[6.1]
  def change
    add_column(:sites, :owner_uid, :string)
    change_column_null(:sites, :owner_uid, false, 'bal35')
  end
end
