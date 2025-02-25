class CarnegieController < SubsitesController
  include ActionController::Live
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]

  layout 'signature'

  configure_blacklight do |config|
    Dcv::Configurators::CarnegieBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  prepend_view_path('app/views/signature')
  prepend_view_path('app/views/carnegie')

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'blue'
  end

  def signature_image_path
    view_context.asset_path("carnegie/ac-signature.svg")
  end

  def signature_banner_image_path
    view_context.asset_path("carnegie/Carnegie_q85-large.jpg")
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
