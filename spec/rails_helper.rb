# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    :timeout => 30
  )
end


Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 30 # Some ajax requests might take longer than the default waut time of 2 seconds.

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods
  # additional factory_bot configuration
  config.before(:suite) do
    #FactoryBot.definition_file_paths = [File.expand_path('../factories', __FILE__)]
    #FactoryBot.find_definitions
  end

  # We're having issues with PhantomJS timing out.  See: https://github.com/teampoltergeist/poltergeist/issues/375
  # Hopefully this will fix the problem.  Solution from: https://gist.github.com/afn/c04ccfe71d648763b306
  config.around(:each, type: :feature) do |ex|
    example = RSpec.current_example
    # Try four times
    3.times do |i|
      ex.run
      break unless example.exception.is_a?(Capybara::Poltergeist::TimeoutError)
      example.instance_variable_set('@exception', nil)
      self.send(:__init_memoized) # clear let variables
      puts("\nCapybara::Poltergeist::TimeoutError at #{example.location}\n   Restarting phantomjs and retrying...")
      restart_phantomjs
    end
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  def restart_phantomjs
    puts "-> Restarting phantomjs: iterating through capybara sessions..."
    session_pool = Capybara.send('session_pool')
    session_pool.each do |mode,session|
      msg = "  => #{mode} -- "
      driver = session.driver
      if driver.is_a?(Capybara::Poltergeist::Driver)
        msg += "restarting"
        driver.restart
      else
        msg += "not poltergeist: #{driver.class}"
      end
      puts msg
    end
  end
end
