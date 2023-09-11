DCV_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/dcv.yml", aliases: true)[Rails.env].with_indifferent_access

# Add audio assets path
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "audio")
Sprockets::Context.send :include, Rails.application.routes.url_helpers

# define field access for the map and geodata panels
Blacklight::Configuration.define_field_access :geo_field

# define field access for the citation panels
Blacklight::Configuration.define_field_access :citation_field

log_dev = Rails.root.join('log', "blacklight_#{Rails.env}.log")
log_level = Blacklight.blacklight_yml.dig(Rails.env, 'logger', 'level') || 'warn'
Blacklight.logger = ActiveSupport::Logger.new(log_dev, level: log_level.to_sym)
