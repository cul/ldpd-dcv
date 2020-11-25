require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# require 'dcv/rails/routing_patches'
require File.expand_path('../../lib/dcv/rails/routing_patches', __FILE__)

module Dcv
  class Application < Rails::Application
    include Cul::Omniauth::FileConfigurable

    #config.middleware.use Rack::Deflater # Use GZip on responses whenever possible

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # See: http://stackoverflow.com/questions/4928664/trying-to-implement-a-module-using-namespaces
    config.autoload_paths += %W(#{config.root}/lib)

    # Custom precompiled asset manifests
    config.assets.precompile += [
        'dcv.css',
        'dcv.js',
        'welcome.js', 'welcome.css',
        'print.css',
        'freelib.js',
        'd3.js',
        'sites.js', 'sites.css',
        'easymde.min.js', 'easymde.min.css'
      ]

    # And include styles for all configured subsite layouts
    subsites_yml_file = "#{Rails.root.to_s}/config/subsites.yml"
    if File.exists?(subsites_yml_file)
      subsite_data = YAML.load_file(subsites_yml_file)[Rails.env]
      unique_layouts = []
      unique_layouts += subsite_data['public'].keys
      unique_layouts += subsite_data['restricted'].keys
      # make sure common layouts are included
      unique_layouts += ['signature', 'gallery', 'portrait']
      unique_layouts.uniq!

      config.assets.precompile += unique_layouts.map{|layout| layout + '.css'}
      config.assets.precompile += unique_layouts.map{|layout| layout + '.js'}
      # add all palette-specific css for layouts
      config.assets.precompile += ['signature-*.css']
      config.assets.precompile += ['gallery-*.css']
      config.assets.precompile += ['portrait-*.css']
      # add the legacy omnibus css
      config.assets.precompile += ['dcv-legacy.css']
    end

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
