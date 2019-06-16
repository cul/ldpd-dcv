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
    until subsite_path.empty?
      subsite_config = subsite_config.fetch('nested',{}).fetch(subsite_path.shift,{})
    end
    subsite_config.with_indifferent_access
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
      config.merge(dig_sites(site['nested'])) if site['nested'] && config.empty?
    end
    config
  end
end