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
      unless has_search_parameters?
        render 'home'
      end
    end
  end

  def about
  end

  private

  def write_csv_line_to_response_stream(csv_line_arr)
    response.stream.write CSV.generate_line(csv_line_arr)
  end

  def stream_csv_response_for_search_results
    response.status = 200
    response.headers["Content-Type"] = "text/csv"
    response.headers['Content-Disposition'] = 'attachment; filename="search_results.csv"'

    field_keys_to_labels = Hash[blacklight_config.show_fields.map{|field_name, field| [field_name, field.label]}].except('lib_project_full_ssim', 'lib_collection_ssm', 'lib_repo_full_ssim', 'lib_name_ssm')

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
          write_csv_line_to_response_stream lcaaj_document_to_csv_row(document, field_keys_to_labels)
        end
      end
    ensure
      response.stream.close
    end
  end

  def lcaaj_document_to_csv_row(document, field_keys_to_labels)
    field_keys_to_labels.keys.map{ |field_key|
      next '' unless document.has?(field_key)
      values = document[field_key]
      values.delete('manuscripts') if field_key == 'lib_format_ssm' # We don't want to include the 'manuscripts' value because other format value is more descriptive
      values.first
    }
  end

end
