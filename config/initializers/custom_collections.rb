CUSTOM_COLLECTIONS = YAML.load_file("#{Rails.root.to_s}/config/collections.yml")[Rails.env]
DEFAULT_COLLECTION = {'layout' => 'dcv'}