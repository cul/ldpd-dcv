class Restricted::IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::IfpBlacklightConfigurator.configure(config)
    Dcv::Configurators::FullTextConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    if has_search_parameters?
      super
    else
      render 'home'
    end
  end

  def partner
    if Ifp::PartnerDataHelper::PARTNER_DATA.has_key?(params[:key].to_sym)
      render 'ifp/partner/index'
    else
      render 'ifp/partner/not_found'
    end
  end

end
