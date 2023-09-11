rails_env = ENV['RAILS_ENV'] || 'development'
resque_config_path = File.join(Rails.root, 'config', 'resque.yml')
resque_config = File.exist?(resque_config_path) ?
  YAML.load_file(resque_config_path, aliases: true)[rails_env] : {}
RESQUE_CONFIG = ActiveSupport::HashWithIndifferentAccess.new(resque_config)

Resque.redis = RESQUE_CONFIG['url']
Resque.redis.namespace = 'resque:' + RESQUE_CONFIG['namespace'] if RESQUE_CONFIG['namespace']

Resque.logger = MonoLogger.new(File.open("#{Rails.root}/log/resque.log", "w+"))
Resque.logger.formatter = Resque::VerboseFormatter.new
