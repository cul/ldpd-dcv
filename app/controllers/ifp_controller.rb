class IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::IfpBlacklightConfigurator.configure(config)
    Dcv::Configurators::FullTextConfigurator.configure(config)
    # Include only this target's content in search results
    config.default_solr_params[:fq] << "publisher_ssim:\"#{subsite_config['uri']}\""
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

  def about_the_ifp
  end

  def about_the_collection
  end

end
