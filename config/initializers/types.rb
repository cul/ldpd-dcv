# config/initializers/types.rb
Rails.application.config.to_prepare do
  ActiveRecord::Type.register(
    :site_permissions,
    Site::Permissions::Type
  )

  ActiveRecord::Type.register(
    :site_search_configuration,
    Site::SearchConfiguration::Type
  )
end
