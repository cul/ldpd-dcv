rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
IIIF_TEMPLATES = YAML.load_file(rails_root + '/config/iiif_templates.yml', aliases: true).with_indifferent_access.freeze