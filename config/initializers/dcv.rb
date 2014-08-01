DCV_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/dcv.yml")[Rails.env]

Sprockets::Context.send :include, Rails.application.routes.url_helpers