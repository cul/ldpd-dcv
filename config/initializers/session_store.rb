# Be sure to restart your server when you modify this file.

if Rails.env.development?
  # In development, use cache_store so that we can push stacktraces into the session for debugging limits.  Cookies impose a data limit that is too low.
  Dcv::Application.config.session_store :cache_store, key: YAML.load_file("#{Rails.root}/config/initializers/initializer_secrets.yml")['session_store_key']
else
  Dcv::Application.config.session_store :cookie_store, key: YAML.load_file("#{Rails.root}/config/initializers/initializer_secrets.yml")['session_store_key']
end
