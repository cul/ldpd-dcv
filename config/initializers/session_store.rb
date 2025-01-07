# Be sure to restart your server when you modify this file.

cookie_opts = ["development", "test"].include?(Rails.env.to_s) ? {} : { same_site: :none, secure: true }
Rails.application.config.session_store(:cookie_store,
  key: Rails.application.config.secret_key_base = Rails.application.credentials.dig(Rails.env.to_sym, :session_store_key),
  **cookie_opts
)
