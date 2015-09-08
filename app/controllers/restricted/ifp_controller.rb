class Restricted::IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::IfpBlacklightConfigurator.configure(config)
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
