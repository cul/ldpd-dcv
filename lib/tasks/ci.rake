require "active-fedora"

namespace :dcv do

  begin
    # This code is in a begin/rescue block so that the Rakefile is usable
    # in an environment where RSpec is unavailable (i.e. production).

    require 'jettywrapper'

    Jettywrapper.url = "https://github.com/projecthydra/hydra-jetty/archive/7.x-stable.zip"
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
    puts "[Warning] Exception creating rspec or jettywrapper rake tasks.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production)."
    puts e
  end

  task reload_fixtures: :environment do
    rubydora = ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials).connection
    obj_sources = {}
    ['catalog','public','restricted','external','internal','item'].each do |catalog_pid|
      fixture_pid = "donotuse:#{catalog_pid}"
      foxml_path = File.join(Rails.root, "spec/fixtures/foxml/#{fixture_pid.gsub(':','_')}.xml")
      mods_path = File.join(Rails.root, "spec/fixtures/mods/#{fixture_pid.gsub(':','_')}_mods.xml")
      obj_sources[fixture_pid] = {foxml: File.read(foxml_path), mods: File.read(mods_path)}
    end
    template_foxml = File.read(File.join(Rails.root, "spec/fixtures/foxml/custom_template.xml"))
    template_mods = File.read(File.join(Rails.root, "spec/fixtures/mods/custom_template_mods.xml"))
    ['carnegie','durst','jay','lcaaj','nyre'].each do |slug|
      custom_pid = "custom:#{slug}"
      obj_sources[custom_pid] = {}
      template_subs = {template: slug, Template: slug.capitalize}
      obj_sources[custom_pid][:foxml] = format(template_foxml, template_subs)
      obj_sources[custom_pid][:mods] = format(template_mods, template_subs)
    end
    obj_sources.each do |fixture_pid, srcs|
      fixture_foxml = srcs[:foxml]
      fixture_mods = srcs[:mods]
      begin
        rubydora.purge_object :pid=>fixture_pid
      rescue RestClient::NotFound; end # it's ok not to exist
      rubydora.ingest(:file=>StringIO.new(fixture_foxml), :pid=>fixture_pid)
      fedora_object = ActiveFedora::Base.find(fixture_pid)
      # Set MODS for publish target titles
      fedora_object.descMetadata.content = fixture_mods
      fedora_object.save(update_index: false)
      # update solr outside IndexFedoraObjectJob, since Site model create/teardown handled in specs
      doc_adapter = Dcv::Solr::DocumentAdapter::ActiveFedora(fedora_object)
      # rsolr params are camelcased
      doc_adapter.update_index(commit: true)
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
      Rake::Task["dcv:sites:seed_from_solr"].invoke
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
      # yml templates
      Dir.glob(File.join(Rails.root, "config/templates/*.template.yml")).each do |template_yml_path|
        target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml", ".yml"))
        FileUtils.touch(target_yml_path) # Create if it doesn't exist
        target_yml = YAML.load_file(target_yml_path) || YAML.load_file(template_yml_path)
        File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
      end
      Dir.glob(File.join(Rails.root, "config/templates/*.template.yml.erb")).each do |template_yml_path|
        target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml.erb", ".yml"))
        FileUtils.touch(target_yml_path) # Create if it doesn't exist
        target_yml = YAML.load_file(target_yml_path) || YAML.load(ERB.new(File.read(template_yml_path)).result(binding))
        File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
      end
    end
  end
end
