source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'
gem 'actionpack-action_caching'
# Hydra stack
gem 'nokogiri', '~> 1.6.3'
gem 'blacklight', '~> 5.7.2'
gem 'hydra-head', '~>7'
gem 'active-fedora', '>= 7.3.1'
#gem 'rubydora', :path => '../rubydora'
gem 'rubydora', :git => 'https://github.com/elohanlon/rubydora', branch: 'datastream_dissemination_with_headers'

# Columbia Hydra models
gem 'cul_hydra', '~> 1.4.12'
#gem 'cul_hydra', :path => '../cul_hydra'
gem 'cul_omniauth', '~>0.5.2'
gem 'active-triples', '~> 0.2.2'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

# Use mysql2 gem for mysql connections
gem 'mysql2', '0.3.18'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.0'
gem 'sass', '>= 3.5.3'

# Use colorbox-rails gem for dialogs
gem 'colorbox-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', '>= 0.12.3',  platforms: :ruby
gem 'libv8', '>= 3.16.14.19' # Min version for Mac OS 10.11, XCode 9.0, Ruby 2.4

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 3.1.3'
gem 'jquery-ui-rails', '~>4.0'

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
gem 'jbuilder', '~> 1.2'

gem 'bootstrap-sass', '>= 3.2'

gem 'leaflet-rails', '~> 1.2.0'

gem 'redcarpet'

gem 'mime-types'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'devise', '~>3.4'
gem "devise-guests", "~> 0.3"

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
  gem 'rspec-rails', '~> 3.4.0'
  gem 'capybara'
  gem 'poltergeist' # For headless-browser JavaScript testing
  gem 'factory_girl_rails', '>= 4.4.1'
  gem 'jettywrapper', '>= 1.5.1'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end

# Add unicorn as available app server
#gem 'unicorn'

# Use Thin for local development
#gem "thin"

# Use Puma for local development
gem 'puma'
