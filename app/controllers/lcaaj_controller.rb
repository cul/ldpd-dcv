class LcaajController < SubsitesController
  include ActionController::Live
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]
  #before_action :set_map_data_json, only: [:index, :map_search]

  prepend_view_path('app/views/signature')
  prepend_view_path('app/views/lcaaj')

  configure_blacklight do |config|
    Dcv::Configurators::LcaajBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def about
  end

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'blue'
  end

  def signature_image_path
    view_context.asset_path("lcaaj/signature.svg")
  end

  def signature_banner_image_path
    view_context.asset_path("lcaaj/lcaaj-c1.png")
  end

  private
  # CSV download  overrides

  def document_to_csv_row(document, field_keys_to_labels)
    field_keys_to_labels.keys.map{ |field_key|
      next '' unless document.has?(field_key)
      values = document[field_key]
      values.delete('manuscripts') if field_key == 'lib_format_ssm' # We don't want to include the 'manuscripts' value because other format value is more descriptive
      values.first
    }
  end

end
