require 'yaml'

source 'https://rubygems.org'

gem 'bigdecimal', '~>3.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.0'
gem 'sassc'

gem 'stringio', '3.1.1'

gem 'bootsnap', '~> 1.9.3'
gem 'actionpack-action_caching'
# Hydra stack
gem 'nokogiri', '~> 1.18', '>= 1.18.9', force_ruby_platform: true
gem 'blacklight', '~> 7.38.0'
gem 'view_component', '~>2.82.0'
gem 'active-fedora', '~> 8.7'
gem 'rdf', '>= 1.1.5'
gem 'rdf-vocab'

# carrierwave for file uploads
gem 'carrierwave', '~> 1.3'
#gem 'rubydora', :path => '../rubydora'
gem 'rubydora'

gem 'cul_omniauth', '~> 0.7.0'
gem 'cancancan'
#gem 'cul_omniauth', git: 'https://github.com/cul/cul_omniauth', branch: '0.5.x'
gem 'active-triples', git: 'https://github.com/cul/ActiveTriples', branch: 'deprecation_update'

# Use wowza token gem for generating tokens
gem 'wowza-secure_token', '0.0.1'

# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.7"

# Use mysql2 gem for mysql connections
gem 'mysql2', '~> 0.5.6'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# Pretty printing
gem 'coderay'

# For retrying code blocks that may return an error
gem 'retriable', '~> 2.1'

# Use resque for background jobs
# We're pinning resque to 1.26.x because 1.27 does an eager load operation
# that doesn't work properly with the Blacklight gem dependency and raises:
# ActiveSupport::Concern::MultipleIncludedBlocks: Cannot define multiple 'included' blocks for a Concern
gem 'resque', '~> 1.26.0'
# Need to lock to earlier version of redis gem because resque 1.26.0 is
# calling Redis.connect, and this method no longer exists in redis gem >= 4.0
gem 'redis', '< 4' # Need to lock to earlier version of redis gem because resque is calling Redis.connect, and this method no longer exists in redis gem >= 4.0

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

gem 'redcarpet'

gem 'mime-types'

gem 'addressable', '~> 2.8.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'devise'
gem "devise-guests", "~> 0.3"

# Gem min versions that are only specified here because of vulnerabilities in earlier versions:
gem 'rubyzip', '>= 1.2.1'
gem 'rack-protection', '>= 1.5.5'
gem 'loofah', '>= 2.2.1'
gem 'best_type'

gem 'sitemap_generator'

# Console text coloring
gem 'rainbow', '~> 3.0'

# Use Puma for local development
gem 'puma', '~> 5.2'

gem "ox", "~> 2.14"

gem "vite_rails", "~> 3.0"
#these gems will no longer be default in ruby 3.4.0
gem "base64"
gem "mutex_m"
gem "csv"
gem "observer"

group :development, :test do
  # Capistrano for deployment (per https://capistranorb.com/documentation/getting-started/installation/)
  gem "capistrano", "~> 3.19.2", require: false
  gem "capistrano-cul", require: false # common set of tasks shared across cul apps
  gem "capistrano-rails", "~> 1.4", require: false # for compiling rails assets
  gem "capistrano-passenger", "~> 0.2", require: false # allows restart passenger workers

  # Use net-ssh >= 4.2 to prevent warnings with Ruby 2.4
  gem 'net-ssh', '>= 4.2'
  gem 'rspec-rails'
  gem 'rspec-json_expectations'
  gem 'react_on_rails'
  gem 'capybara', '~> 3.32'
  # For testing with chromedriver for headless-browser JavaScript testing
  gem 'selenium-webdriver', '~> 4.16.0'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rubocop', '~> 0.53.0', require: false
  gem 'rubocop-rspec', '>= 1.20.1', require: false
  gem 'rubocop-rails_config', require: false
  gem 'listen'
end
