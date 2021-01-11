class Restricted::CatalogController < SubsitesController

  def search_builder
    super.tap { |builder| builder.processor_chain.concat [:hide_concepts_when_query_blank_filter] }
  end
  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config, true)
  end

end
