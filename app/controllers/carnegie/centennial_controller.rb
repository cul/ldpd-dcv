module Carnegie
class CentennialController < SubsitesController
  include ActionController::Live
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]

  layout 'signature'

  configure_blacklight do |config|
    Dcv::Configurators::CarnegieBlacklightConfigurator.configure(config)
    config.show.route = { controller: 'carnegie/centennial' }

    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def index
    params[:search_field] = 'all_text_teim' unless has_search_parameters?
    if request.format.csv?
      stream_csv_response_for_search_results
    else
      super
    end
  end

  def about
  end

  def faq
  end

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'oceanStripe'
  end

  def signature_image_path
    view_context.asset_path("carnegie/ac-signature.svg")
  end

  def signature_banner_image_path
    view_context.asset_path("carnegie/Carnegie_q85-large.jpg")
  end

  # override for namespaced controller
  def tracking_method
    "track_carnegie_centennial_path"
  end

  private

  # CSV download  overrides
  def field_keys_to_labels
    super.tap do |results|
      results['interviewer_name'] = 'Interviewer'
      results['interviewee_name'] = 'Interviewee'
    end
  end

  def document_to_csv_row(document, field_keys_to_labels)
    if document.key?('lib_name_ssm')
      document['lib_name_ssm'].each do |name_value|
        if name_value.start_with?('Interviewer')
          document['interviewer_name'] = [name_value]
          next
        elsif name_value.start_with?('Interviewee')
          document['interviewee_name'] = [name_value]
          next
        end
      end
    end

    field_keys_to_labels.keys.map{ |field_key|
      next '' unless document.has?(field_key)
      values = document[field_key]
      # We don't want to include the 'manuscripts' value because other format value is more descriptive
      values.delete('manuscripts') if (field_key == 'lib_format_ssm') && values[1]
      values.first
    }
  end
end
end
