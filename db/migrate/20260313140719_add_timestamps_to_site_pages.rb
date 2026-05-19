class AddTimestampsToSitePages < ActiveRecord::Migration[6.1]
  def up
    add_timestamps :site_pages, null: true

    # Reset any cached data
    SitePage.reset_column_information

    # backfill timestamps for existing records
    SitePage.update_all(created_at: Time.current, updated_at: Time.current)

    change_column_null :site_pages, :created_at, false
    change_column_null :site_pages, :updated_at, false
  end

  def down
    remove_timestamps :site_pages
    # Reset any cached data
    SitePage.reset_column_information
  end
end
