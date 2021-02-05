class SubsiteConfig
  extend Forwardable

  attr_accessor :config

  def_delegator :@config, :[], :each

  def initialize(config={})
    @config = config
  end

  def self.for_path(controller_path, restricted)
    subsite_config = {'nested' => SUBSITES[(restricted ? 'restricted' : 'public')]}
    subsite_path = controller_path.split('/')
    subsite_path.shift if restricted
    return {} unless subsite_path.present?
    subsite_slug = subsite_path.join('/')
    until subsite_path.empty?
      subsite_config = subsite_config.fetch('nested',{}).fetch(subsite_path.shift,{})
    end
    if subsite_config.empty?
      return subsite_config
    end
    subsite_config['slug'] = subsite_slug
    subsite_config['restricted'] = restricted
    subsite_config.with_indifferent_access
  end

  def date_search_configuration
    obj = Site::DateSearchConfiguration.new
    config['date_search']&.tap do |legacy_config|
      obj.show_sidebar = legacy_config['sidebar'] || false
      obj.show_timeline = legacy_config['timeline'] || false
      obj.sidebar_label = legacy_config['label'] || 'Date Range'
      obj.enabled = (legacy_config['sidebar'] || legacy_config['timeline']) ? true : false
    end
    obj
  end

  def display_options
    obj = Site::DisplayOptions.new
    obj.default_search_mode = config.fetch('default_search_mode', 'grid')
    obj.show_csv_results = config.fetch('show_csv_results', false)
    obj.show_original_file_download = config.fetch('show_original_file_download', false)
    obj.show_other_sources = config.fetch('show_other_sources', false)
    obj
  end

  def map_configuration
    obj = Site::MapConfiguration.new
    config['map_search']&.tap do |legacy_config|
      obj.show_sidebar = legacy_config.fetch('sidebar', false)
      obj.show_items = legacy_config.fetch('items', true)
      obj.default_lat = legacy_config['default_lat']
      obj.default_long = legacy_config['default_long']
      obj.enabled = (legacy_config['default_lat'] || legacy_config['default_long']) ? true : false
      case legacy_config['default_zoom']
      when 11
        obj.granularity_data = 'street'
        obj.granularity_search = 'city'
      else
        if obj.enabled
          obj.granularity_data = 'city'
          obj.granularity_search = 'country'
        end
      end
    end
    obj
  end

  def site_permissions
    obj = Site::Permissions.new
    obj.remote_ids = config['remote_ids']
    obj.remote_roles = config['remote_roles']
    obj.locations = config['locations']
    obj
  end

  # publisher_ssim values are fedora_uri values
  def self.for_fedora_uri(fedora_uri)
    subsite_config = {}
    ['restricted', 'public'].each do |root|
      subsite_config.merge!(dig_sites(SUBSITES[root], fedora_uri))
      break unless subsite_config.empty?
    end
    subsite_config.with_indifferent_access
  end

  def self.dig_sites(sites, fedora_uri)
    config = {}
    sites.each do |key, site|
      break unless config.empty?
      config.merge!(site) if site['uri'].eql?(fedora_uri)
      config.merge!(dig_sites(site['nested'], fedora_uri)) if site['nested'] && config.empty?
    end
    config
  end
end