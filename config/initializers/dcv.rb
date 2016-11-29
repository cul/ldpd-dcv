DCV_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/dcv.yml")[Rails.env].with_indifferent_access

Sprockets::Context.send :include, Rails.application.routes.url_helpers