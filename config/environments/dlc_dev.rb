require Rails.root.join('config/environments/deployed.rb')

Rails.application.configure do
  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'dlc-rails-dev1.cul.columbia.edu' }

  # Set default host for sitemap generator
  config.default_host = 'https://dlc-dev.library.columbia.edu'

  config.log_level = :debug
end
