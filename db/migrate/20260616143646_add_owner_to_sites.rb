class AddOwnerToSites < ActiveRecord::Migration[6.1]
  def change
    add_column(:sites, :owner_uid, :string)
    default_owner = Rails.application.config_for(:dcv).default_owner
    change_column_null(:sites, :owner_uid, false, default_owner)
  end
end
