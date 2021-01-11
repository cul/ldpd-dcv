class LehmanController < SubsitesController
  include ActionController::Live

  configure_blacklight do |config|
    Dcv::Configurators::LehmanBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def index
    if request.format.csv?
      stream_csv_response_for_search_results
    else
      super
      if !has_search_parameters? && request.format.html?
        # we override the view rendered for the subsite home on html requests
        params[:action] = 'home'
        render 'home'
      end
    end
  end

  private

  def document_to_csv_row(document, field_keys_to_labels)
    field_keys_to_labels.keys.map{ |field_key|
      next '' unless document.has?(field_key)
      values = document[field_key]
      # We don't want to include the 'manuscripts' value because other format value is more descriptive
      values.delete('manuscripts') if (field_key == 'lib_format_ssm') && values[1]
      values.first
    }
  end
end
