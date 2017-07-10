class Restricted::CatalogController < SubsitesController

  self.solr_search_params_logic += [:hide_concepts_when_query_blank_filter]

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    publishers.compact!
    config.default_solr_params[:fq] << 'publisher_ssim:("' + publishers.join('" OR "') + '")'

    # Do not include the catalog publish target or any additional publish targets defined in search results
    config.default_solr_params[:fq] << '-id:("' + publishers.map{|info_fedora_prefixed_pid| info_fedora_prefixed_pid.gsub('info:fedora/', '') }.join('" OR "') + '")'
  end

end
