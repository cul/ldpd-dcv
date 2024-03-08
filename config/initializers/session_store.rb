# Be sure to restart your server when you modify this file.

cookie_opts = ["development", "test"].include?(Rails.env.to_s) ? {} : { same_site: :none, secure: true }
Rails.application.config.session_store(:cookie_store,
  key: YAML.load_file("#{Rails.root}/config/initializer_secrets.yml", aliases: true)['session_store_key'],
  **cookie_opts
)
