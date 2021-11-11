class Restricted::CatalogController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config, true)
  end

  def search_service_context
    { builder: { addl_processor_chain: [:hide_concepts_when_query_blank_filter] } }
  end
end
