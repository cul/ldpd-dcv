class IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::IfpBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  prepend_view_path('app/views/signature')
  prepend_view_path('app/views/ifp')

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

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'monochrome'
  end

  def carousel_image_paths
    @carousel_image_paths ||= [
      "ifp/home-ss/home-image-0.jpg",
      "ifp/home-ss/home-image-1.jpg",
      "ifp/home-ss/home-image-2.jpg",
      "ifp/home-ss/home-image-3.jpg",
      "ifp/home-ss/home-image-4.jpg",
      "ifp/home-ss/home-image-5.jpg",
      "ifp/home-ss/home-image-6.jpg",
      "ifp/home-ss/home-image-7.jpg"
    ].map { |path| view_context.asset_path(path) }
  end
end
