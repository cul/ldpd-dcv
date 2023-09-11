require "active-fedora"

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
    puts "[Warning] Exception creating rspec or testing rake tasks.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production)."
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
      desc_metadata = fedora_object.create_datastream(Cul::Hydra::Datastreams::ModsDocument, "descMetadata", controlGroup: 'M')
      desc_metadata.content = fixture_mods
      fedora_object.add_datastream(desc_metadata)
      fedora_object.save!(update_index: false)
      # update solr outside IndexFedoraObjectJob, since Site model create/teardown handled in specs
      doc_adapter = Dcv::Solr::DocumentAdapter::ActiveFedora(fedora_object)
      # rsolr params are camelcased
      doc_adapter.update_index(commit: true)
    end
  end
  desc "CI build"
  task :ci do
    rspec_system_exit_failure_exception = nil

    task_stack = ['dcv:ci_specs']
    task_stack.prepend('dcv:ci:docker_wrapper')

    duration = Benchmark.realtime do
      ENV['RAILS_ENV'] = 'test'
      Rails.env = ENV['RAILS_ENV']

      puts "setting up template config files...\n"
      Rake::Task["dcv:ci:config_files"].invoke
      puts "setting up template docker files...\n"
      Rake::Task["dcv:docker:setup_config_files"].invoke

      # A webpacker recompile isn't strictly required, but it speeds up the first feature test run and
      # can prevent first feature test timeout issues, especially in a slower CI server environment.
      if ENV['WEBPACKER_RECOMPILE'] == 'true'
        puts 'Recompiling pack...'
        recompile_duration = Benchmark.realtime do
          Rake::Task['webpacker:compile'].invoke
        end
        puts "Done recompiling pack.  Took #{recompile_duration} seconds."
      end

      puts "setting up test db...\n"
      Rake::Task['db:environment:set'].invoke
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      puts "compiling assets...\n"
      Rake::Task['assets:precompile'].invoke
      begin
        Rake::Task[task_stack.shift].invoke(task_stack)
      rescue SystemExit => e
        rspec_system_exit_failure_exception = e
      end
    end
    puts "\nCI run finished in #{duration} seconds."
    # Re-raise caught exit exception (if present) AFTER solr shutdown and CI duration display.
    # This exception triggers an exit call with the original error code sent out by rspec failure.
    raise rspec_system_exit_failure_exception unless rspec_system_exit_failure_exception.nil?
  end

  task :ci_specs do
    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']

    Rake::Task["dcv:reload_fixtures"].invoke
    Rake::Task["dcv:sites:seed_from_solr"].invoke
    Rake::Task["dcv:coverage"].invoke
  end

  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'
    Rake::Task["dcv:rspec"].invoke
  end

  namespace :ci do
    # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
    task :config_files do
      # yml templates
      Dir.glob(File.join(Rails.root, "config/templates/*.template.yml")).each do |template_yml_path|
        target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml", ".yml"))
        FileUtils.touch(target_yml_path) # Create if it doesn't exist
        target_yml = YAML.load_file(target_yml_path, aliases: true) || YAML.load_file(template_yml_path, aliases: true)
        File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
      end
      Dir.glob(File.join(Rails.root, "config/templates/*.template.yml.erb")).each do |template_yml_path|
        target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml.erb", ".yml"))
        FileUtils.touch(target_yml_path) # Create if it doesn't exist
        target_yml = YAML.load_file(target_yml_path, aliases: true) || YAML.load(ERB.new(File.read(template_yml_path)).result(binding), aliases: true)
        File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
      end
    end

    task :docker_wrapper, [:task_stack] => [:environment] do |task, args|
      unless Rails.env.test?
        raise 'This task should only be run in the test environment (because it clears docker volumes)'
      end
      task_stack = args[:task_stack]
      # stop docker if it's currently running (so we can delete any old volumes)
      Rake::Task['dcv:docker:stop'].invoke
      # rake tasks must be re-enabled if you want to call them again later during the same run
      Rake::Task['dcv:docker:stop'].reenable

      ENV['rails_env_confirmation'] = Rails.env # setting this to skip prompt in volume deletion task
      Rake::Task['dcv:docker:delete_volumes'].invoke
      Rake::Task['dcv:docker:start'].invoke
      begin
        Rake::Task[task_stack.shift].invoke(task_stack) while task_stack.present?
      rescue SystemExit => e
        rspec_system_exit_failure_exception = e
      end
      Rake::Task['dcv:docker:stop'].invoke
      raise rspec_system_exit_failure_exception if rspec_system_exit_failure_exception
    end
  end
end
