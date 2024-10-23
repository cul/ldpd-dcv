class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::JayBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  prepend_view_path('app/views/signature')
  prepend_view_path('app/views/jay')
end
