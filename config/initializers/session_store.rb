# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: YAML.load_file("#{Rails.root}/config/initializer_secrets.yml", aliases: true)['session_store_key']
