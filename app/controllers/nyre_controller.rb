class NyreController < SubsitesController
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]
  #before_action :set_map_data_json, only: [:index, :map_search]

  configure_blacklight do |config|
    Dcv::Configurators::NyreBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  prepend_view_path('app/views/signature')
  prepend_view_path('app/views/nyre')

  def about
  end

  def aboutcollection
  end

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'blue'
  end

  def signature_image_path
    nil
  end

  def signature_banner_image_path
    view_context.asset_path("nyre/nyre-collage.png")
  end

end
