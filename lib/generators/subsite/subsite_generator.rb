class SubsiteGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :subsite_name, :type => :string
  class_option :restricted, :type => :boolean, :default => false, :description => "Make this a restricted subsite"
  
  def copy_template_files
    #copy_file "file.rb", "app/controllers/file.rb"
    puts "This generator has not been fully implemented yet.  Would have created subsite for #{subsite_name}"
    
    if yes?("Test user interaction (no changes will be made): Do you want to say yes? [y|n]")
      puts 'Would have done something.'
    end
    
  end
  
end
