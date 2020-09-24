class LcaajController < SubsitesController
  include ActionController::Live
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]
  #before_action :set_map_data_json, only: [:index, :map_search]

  configure_blacklight do |config|
    Dcv::Configurators::LcaajBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    if request.format.csv?
      stream_csv_response_for_search_results
    else
      super
      if !has_search_parameters? && request.format.html?
        # we override the view rendered for the subsite home on html requests
        render 'home'
      end
    end
  end

  def about
  end

  def subsite_layout
    'lcaaj'
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
