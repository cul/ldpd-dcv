DCV_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/dcv.yml")[Rails.env].with_indifferent_access

Sprockets::Context.send :include, Rails.application.routes.url_helpers

# define field access for the map and geodata panels
Blacklight::Configuration.define_field_access :geo_field
