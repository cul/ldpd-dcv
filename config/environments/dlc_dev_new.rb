# frozen_string_literal: true

require Rails.root.join("config/environments/deployed.rb")

Rails.application.configure do
  config.log_level = :debug

  config.action_mailer.default_url_options = { host: "dlc-rails-dev1.cul.columbia.edu" }
end
