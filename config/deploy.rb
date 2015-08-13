set :default_stage, "dcv_dev"
set :stages, %w(dcv_dev dcv_test dcv_prod dcv_private_dev dcv_private_test dcv_private_prod)

set :keep_releases, 2 # Only keep 2 releases at a time

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'date'

default_run_options[:pty] = true

set :application, "dcv"
set :branch do
  default_tag = `git tag`.split("\n").last

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

set :scm, :git
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :repository,  "git@github.com:cul/dcv.git"
set :use_sudo, false

# Note: The line below is meaningless. It's just a workaround for Rails 4.0 because
# in 4.0, initializers and the database configuration are always loaded before
# precompiling assets.  This doesn't work for us because we add the database symlink
# at the end.  Maybe later, we'll see if we can just set up the database symlink earlier
# in the deploy process, but hopefully this will work as a fix for now.
# See: https://iprog.com/posting/2013/07/errors-when-precompiling-assets-in-rails-4-0
set :asset_env, "RAILS_GROUPS=assets DATABASE_URL=mysql2://user:pass@127.0.0.1/dbname"

namespace :deploy do
  desc "Add tag based on current version"
  task :auto_tag, :roles => :app do
    current_version = 'v' +
                      IO.read("VERSION").strip +
                      "/" +
                      DateTime.now.strftime("%Y%m%d")
    tag = Capistrano::CLI.ui.ask "Tag to add: [#{current_version}] "
    tag = current_version if tag.empty?

    system("git tag -a #{tag} -m 'auto-tagged' && git push origin --tags")
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "mkdir -p #{current_path}/tmp/cookies"
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/wind.yml #{release_path}/config/wind.yml"
    run "ln -nfs #{deploy_to}shared/fedora.yml #{release_path}/config/fedora.yml"
    run "ln -nfs #{deploy_to}shared/solr.yml #{release_path}/config/solr.yml"
    run "ln -nfs #{deploy_to}shared/dcv.yml #{release_path}/config/dcv.yml"
    run "ln -nfs #{deploy_to}shared/default_user_accounts.yml #{release_path}/config/default_user_accounts.yml"
    run "ln -nfs #{deploy_to}shared/initializer_secrets.yml #{release_path}/config/initializer_secrets.yml"
    run "ln -nfs #{deploy_to}shared/resque.yml #{release_path}/config/resque.yml"
    run "ln -nfs #{deploy_to}shared/roles.yml #{release_path}/config/roles.yml"
    run "ln -nfs #{deploy_to}shared/cas.yml #{release_path}/config/cas.yml"
    run "mkdir -p #{release_path}/db"
    run "ln -nfs #{deploy_to}shared/#{rails_env}.sqlite3 #{release_path}/db/#{rails_env}.sqlite3"
  end


  desc "Compile assets"
  task :assets do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec rake assets:clean assets:precompile"
  end
  
  desc "Restart Resque Workers"
  task :restart_workers, :roles => :worker do
    run_remote_rake "resque:restart_workers"
  end

end



after 'deploy:update_code', 'deploy:symlink_shared'
before "deploy:create_symlink", "deploy:assets"
after "deploy:update", "deploy:cleanup" # Clean up old releases, set by :keep_releases



# For resetting Resque workers

after 'deploy:restart', 'deploy:restart_workers'

def run_remote_rake(rake_cmd)
  rake_args = ENV['RAKE_ARGS'].to_s.split(',')

  cmd = "cd #{fetch(:latest_release)} && bundle exec #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
  cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
  run cmd
  set :rakefile, nil if exists?(:rakefile)
end
