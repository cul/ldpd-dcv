require "active-fedora"
require 'jettywrapper'

Jettywrapper.url = "https://github.com/projecthydra/hydra-jetty/archive/7.x-stable.zip"

namespace :dcv do

  begin
    # This code is in a begin/rescue block so that the Rakefile is usable
    # in an environment where RSpec is unavailable (i.e. production).

    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rspec_opts = ['--backtrace'] if ENV['CI']
    end

    RSpec::Core::RakeTask.new(:rcov) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rcov = true
    end

    require 'rubocop/rake_task'
    desc 'Run style checker'
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.requires << 'rubocop-rspec'
      task.fail_on_error = false
    end

  rescue LoadError => e
    puts "[Warning] Exception creating rspec rake tasks.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production)."
    puts e
  end

  task reload_fixtures: :environment do
    rubydora = ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials).connection
    ['catalog','public','restricted','external','internal'].each do |catalog_pid|
      catalog_pid = "donotuse:#{catalog_pid}"
      catalog_foxml = begin
        fpath = File.join(Rails.root, "spec/fixtures/foxml/#{catalog_pid.gsub(':','_')}.xml")
        foxml = File.read(fpath)
        foxml
      end
      begin
        rubydora.purge_object :pid=>catalog_pid
      rescue RestClient::NotFound; end # it's ok not to exist
      rubydora.ingest(:file=>StringIO.new(catalog_foxml), :pid=>catalog_pid)
      fedora_object = ActiveFedora::Base.find(catalog_pid)
      # Set MODS for publish target titles
      mods_xml = begin
        fpath = File.join(Rails.root, "spec/fixtures/mods/#{catalog_pid.gsub(':','_')}_mods.xml")
        mods = File.read(fpath)
        mods
      end
      fedora_object.descMetadata.content = mods_xml
      fedora_object.save(update_index: true)
    end
  end
  desc "CI build"
  task :ci do
    
    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']

    Jettywrapper.jetty_dir = File.join(Rails.root, 'jetty-test')

    unless File.exists?(Jettywrapper.jetty_dir)
      puts "\n"
      puts 'No test jetty found.  Will download / unzip a copy now.'
      puts "\n"
    end
    
    Rake::Task["jetty:clean"].invoke
    Rake::Task["dcv:ci:config_files"].invoke
    Rake::Task["dcv:ci:solr_cores"].invoke

    jetty_params = Jettywrapper.load_config.merge({jetty_home: Jettywrapper.jetty_dir})
    
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["dcv:reload_fixtures"].invoke
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
      Rake::Task["dcv:coverage"].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'
    Rake::Task["dcv:rspec"].invoke
  end

  namespace :ci do
    task :solr_cores do
      env_name = ENV['RAILS_ENV'] || 'development'

      ## Copy cores ##
      FileUtils.cp_r('spec/fixtures/solr', File.join(Jettywrapper.jetty_dir, 'solr/dcv_' + env_name))
      ## Copy solr.xml template ##
      FileUtils.cp_r('spec/fixtures/solr.xml', File.join(Jettywrapper.jetty_dir, 'solr'))

      # Update solr.xml configuration file so that it recognizes this code
      solr_xml_data = File.read(File.join(Jettywrapper.jetty_dir, 'solr/solr.xml'))
      solr_xml_data.gsub!('#{env_name}', env_name)
      File.open(File.join(Jettywrapper.jetty_dir, 'solr/solr.xml'), 'w') { |file| file.write(solr_xml_data) }
    end

    # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
    task :config_files do

      # Set up files
      default_development_port = 8983
      default_test_port = 9983

      # database.yml
      database_yml_file = File.join(Rails.root, 'config/database.yml')
      FileUtils.touch(database_yml_file) # Create if it doesn't exist
      database_yml = YAML.load_file(database_yml_file) || {}
      ['development', 'test'].each do |env_name|
        database_yml[env_name] ||= {
          'adapter' => 'sqlite3',
          'database' => 'db/' + env_name + '.sqlite3',
          'pool' => 5,
          'timeout' => 5000
        }
      end
      File.open(database_yml_file, 'w') {|f| f.write database_yml.to_yaml }

      # fedora.yml
      fedora_yml_file = File.join(Rails.root, 'config/fedora.yml')
      FileUtils.touch(fedora_yml_file) # Create if it doesn't exist
      fedora_yml = YAML.load_file(fedora_yml_file) || {}
      ['development', 'test'].each do |env_name|
        fedora_yml[env_name] ||= {
          :user => 'fedoraAdmin',
          :password => 'fedoraAdmin',
          :url => 'http://localhost:' + (env_name == 'test' ? default_test_port : default_development_port).to_s + (env_name == 'test' ? '/fedora-test' : '/fedora'),
          :time_zone => 'America/New_York'
        }
      end
      File.open(fedora_yml_file, 'w') {|f| f.write fedora_yml.to_yaml }

      # secrets.yml
      secrets_yml_file = File.join(Rails.root, 'config/secrets.yml')
      FileUtils.touch(secrets_yml_file) # Create if it doesn't exist
      secrets_yml = YAML.load_file(secrets_yml_file) || {}
      ['development', 'test'].each do |env_name|
        secrets_yml[env_name] ||= {
          'secret_key_base' => SecureRandom.hex(64),
          'session_store_key' =>  '_dcv_' + env_name + '_session_key'
        }
      end
      File.open(secrets_yml_file, 'w') {|f| f.write secrets_yml.to_yaml }

      # solr.yml
      solr_yml_file = File.join(Rails.root, 'config/solr.yml')
      FileUtils.touch(solr_yml_file) # Create if it doesn't exist
      solr_yml = YAML.load_file(solr_yml_file) || {}
      ['development', 'test'].each do |env_name|
        solr_yml[env_name] ||= {
          'url' => 'http://localhost:' + (env_name == 'test' ? default_test_port : default_development_port).to_s + '/solr/dcv_' + env_name
        }
      end
      File.open(solr_yml_file, 'w') {|f| f.write solr_yml.to_yaml }

      # cas.yml
      cas_yml_file = File.join(Rails.root, 'config/cas.yml')
      FileUtils.touch(cas_yml_file) # Create if it doesn't exist
      cas_yml = YAML.load_file(cas_yml_file) || {}
      ['development', 'test'].each do |env_name|
        cas_yml[env_name] ||= {
          'provider' => 'developer'
        }
      end
      File.open(cas_yml_file, 'w') {|f| f.write cas_yml.to_yaml }

      # dcv.yml
      dcv_yml_file = File.join(Rails.root, 'config/dcv.yml')
      FileUtils.touch(dcv_yml_file) # Create if it doesn't exist
      dcv_yml = YAML.load_file(dcv_yml_file) || {}
      ['development', 'test'].each do |env_name|
        dcv_yml[env_name] ||= {
          require_authentication: false,
          cdn_url: 'http://localhost'
        }
      end
      File.open(dcv_yml_file, 'w') {|f| f.write dcv_yml.to_yaml }
      
      # subsites.yml
      subsites_yml_file = File.join(Rails.root, 'config/subsites.yml')
      FileUtils.touch(subsites_yml_file) # Create if it doesn't exist
      subsites_yml = YAML.load_file(subsites_yml_file) || {}
      ['development', 'test'].each do |env_name|
        subsites_yml[env_name] ||= {
          'public' => {
            'catalog' => {
              'layout' => 'dcv',
              'remote_request_api_key' => 'sample_key',
              'date_search' => {
                'sidebar' => true,
                'timeline' => true
              }
            }
          },
          'restricted' => {
            'ifp' => {
              'layout' => 'ifp',
              'show_original_file_download' => true
            }
          }
        }
      end
      File.open(subsites_yml_file, 'w') {|f| f.write subsites_yml.to_yaml }
    end
  end
end
