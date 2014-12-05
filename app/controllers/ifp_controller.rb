class IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::IfpBlacklightConfigurator.configure(config)
  end

  def index
    if has_search_parameters?
      super
    else
      render 'home'
    end
  end
 
  def partner
    if params[:key].index('..') == nil && File.exists?(Rails.root.join("app", "views", 'ifp/partner', "#{params[:key]}.html.erb")) 
      partial_file_path = 'ifp/partner/'+params[:key]
      render partial_file_path
    else
      render 'ifp/partner/not_found'
    end
  end

end
