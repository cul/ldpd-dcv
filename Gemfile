source 'https://rubygems.org'
gem 'bigdecimal', '~>1.4.4'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.5'
gem 'webpacker', '~> 5.2'
gem 'bootsnap'
gem 'actionpack-action_caching'
# Hydra stack
gem 'nokogiri', '~> 1.8.2'
gem 'blacklight', '~> 7.6.0'
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
gem 'active-triples', '~> 0.4.0'

# Use wowza token gem for generating tokens
gem 'wowza-secure_token', '0.0.1'

# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"

# Use mysql2 gem for mysql connections
gem 'mysql2', '0.5.2'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'libv8', '>= 8.4.255.0' # Min version for Mac OS 10.15

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

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

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

group :development, :test do
  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.5.0', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', '~> 0.1', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', '~> 0.1', require: false
  # Use net-ssh >= 4.2 to prevent warnings with Ruby 2.4
  gem 'net-ssh', '>= 4.2'
  gem 'rspec-rails'
  gem 'rspec-json_expectations'
  gem 'capybara', '~> 3.32'
  # For testing with chromedriver for headless-browser JavaScript testing
  gem 'selenium-webdriver', '~> 3.142'
  # For automatically updating chromedriver
  gem 'webdrivers', '~> 4.0', require: false
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'jettywrapper', '>=2.0.5', git: 'https://github.com/samvera-deprecated/jettywrapper.git', branch: 'master'
  gem 'solr_wrapper', '~> 2.0'
  gem 'rubocop', '~> 0.53.0', require: false
  gem 'rubocop-rspec', '>= 1.20.1', require: false
  gem 'rubocop-rails_config', require: false
  gem 'listen'
end

# Add unicorn as available app server
#gem 'unicorn'

# Use Thin for local development
#gem "thin"

# Use Puma for local development
gem 'puma', '~> 5.2'
