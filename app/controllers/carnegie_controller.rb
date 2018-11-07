class CarnegieController < SubsitesController

  before_action :set_map_data_json, only: [:map_search]
  #before_action :set_map_data_json, only: [:index, :map_search]

  configure_blacklight do |config|
    Dcv::Configurators::CarnegieBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    if request.format.csv?
      stream_csv_response_for_search_results
    else
  	  super
      unless has_search_parameters?
        render 'home'
      end
    end
  end

  def map_search
  end

  def about
  end

  private

  def set_map_data_json
    unless has_search_parameters?
      map_cache_key = subsite_key + '_map_search_data_json'
      @map_data_json = Rails.cache.fetch(map_cache_key)
      if @map_data_json.nil?
        (@response, @document_list) = get_search_results(params, {:rows => 200000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}) # Calling get_search_results manually so that we always plot all points for the home page map
        cache_expiration_time = Rails.env.development? ? 5.minutes : 1.day
        map_data = extract_map_data_from_document_list(@document_list)
        @map_data_json = map_data.to_json
        Rails.cache.write(map_cache_key, @map_data_json, expires_in: cache_expiration_time)
      end
    end
  end

  def write_csv_line_to_response_stream(csv_line_arr)
    response.stream.write CSV.generate_line(csv_line_arr)
  end

  def stream_csv_response_for_search_results
    response.status = 200
    response.headers["Content-Type"] = "text/csv"
    response.headers['Content-Disposition'] = 'attachment; filename="search_results.csv"'

    field_keys_to_labels = Hash[blacklight_config.show_fields.map{|field_name, field| [field_name, field.label]}].except('lib_project_full_ssim', 'lib_collection_ssm', 'lib_repo_full_ssim', 'lib_name_ssm')
    # Special handling for name fields
    field_keys_to_labels['interviewer_name'] = 'Interviewer'
    field_keys_to_labels['interviewee_name'] = 'Interviewee'

    # Write out header row
    write_csv_line_to_response_stream(field_keys_to_labels.values)

    # Export ALL search results, not just a single page worth of results
    # Do the export in batches of 1000 so that we don't use massive
    # amounts of memory for large result sets (e.g. 100,000 docs)
    # Stream potentially large CSV response to keep memory usage low
    page = -1
    per_page = 2000
    fl = field_keys_to_labels.keys.join(',') # only retrieve the fields we care about. much faster than asking for all fields.
    begin
      while (
        (@response, @document_list) = get_search_results(params, {start: (page+=1) * per_page, rows: per_page, fl: fl})
      )[1].present? do
        @document_list.each do |document|
          write_csv_line_to_response_stream carnegie_document_to_csv_row(document, field_keys_to_labels)
        end
      end
    ensure
      response.stream.close
    end
  end

  def carnegie_document_to_csv_row(document, field_keys_to_labels)
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
      values.delete('manuscripts') if field_key == 'lib_format_ssm' # We don't want to include the 'manuscripts' value because other format value is more descriptive
      values.first
    }
  end

end
