lock '~>3.17.0'

set :department, 'ldpd'
set :instance, fetch(:department)
set :application, 'dlc'
set :repo_name, "ldpd-dcv"
set :deploy_name, "#{fetch(:application)}_#{fetch(:stage)}"
# used to run rake db:migrate, etc
# Default value for :rails_env is fetch(:stage)
set :rails_env, fetch(:deploy_name)
# use the rvm wrapper
set :rvm_custom_path, '~/.rvm-alma8'
set :rvm_ruby_version, fetch(:deploy_name)

set :repo_url,  "git@github.com:cul/#{fetch(:repo_name)}.git"

set :remote_user, "#{fetch(:instance)}serv"
# Default deploy_to directory is /var/www/:application
# set :deploy_to, '/var/www/my_app_name'
set :deploy_to,   "/opt/passenger/#{fetch(:deploy_name)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug
set :log_level, :info

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log','tmp/pids', 'public/images/sites', 'node_modules', 'public/packs')

# Default value for keep_releases is 5
set :keep_releases, 3

set :passenger_restart_with_touch, true

# Default value for default_env is {}
set :default_env, { NODE_ENV: 'production' }

set :linked_files, fetch(:linked_files, []).push(
  "config/cas.yml",
  "config/database.yml",
  "config/dcv.yml",
  "config/default_user_accounts.yml",
  "config/fedora.yml",
  "config/initializer_secrets.yml",
  "config/resque.yml",
  "config/blacklight.yml",
  "config/solr.yml",
  "config/subsites.yml",
  "config/wind.yml",
  "config/location_uris.yml",
  "public/robots.txt"
)

namespace :deploy do
  desc "Report the environment"
  task :report do
    run_locally do
      puts "cap called with stage = \"#{fetch(:stage,'none')}\""
      puts "cap would deploy to = \"#{fetch(:deploy_to,'none')}\""
      puts "cap would install from #{fetch(:repo_url)}"
      puts "cap would install in Rails env #{fetch(:rails_env)}"
    end
  end

  desc "Add tag based on current version from VERSION file"
  task :auto_tag do
    current_version = "v#{IO.read("VERSION").strip}"

    ask(:tag, current_version)
    tag = fetch(:tag)

    system("git tag -a #{tag} -m 'auto-tagged' && git push origin --tags")
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'resque:restart_workers'
        end
      end
    end
  end
end
