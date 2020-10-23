# Be sure to restart your server when you modify this file.

Dcv::Application.config.session_store :cookie_store, key: YAML.load_file("#{Rails.root}/config/initializer_secrets.yml")['session_store_key']
