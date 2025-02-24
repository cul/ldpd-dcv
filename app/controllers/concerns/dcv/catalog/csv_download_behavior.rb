module Dcv::Catalog::CsvDownloadBehavior
  extend ActiveSupport::Concern

  def write_csv_line_to_response_stream(csv_line_arr)
    response.stream.write CSV.generate_line(csv_line_arr)
  end

  def stream_csv_response_for_search_results
    response.status = 200
    response.headers["Content-Type"] = "text/csv"
    response.headers['Content-Disposition'] = 'attachment; filename="search_results.csv"'

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
      while @document_list&.[](1).present? do
        @document_list.each do |document|
          write_csv_line_to_response_stream document_to_csv_row(document, field_keys_to_labels)
        end
        (@response, @document_list) = search_results(params) do |builder|
          builder.start = ((page+=1) * per_page)
          builder.rows = per_page
          builder.merge(fl: fl)
        end
      end
    ensure
      response.stream.close
    end
  end

  # Overridable methods for controllers
  def csv_field_exclusions
    ['lib_project_full_ssim', 'lib_collection_ssm', 'lib_repo_full_ssim', 'lib_name_ssm']
  end

  def field_keys_to_labels
    tuples = blacklight_config.show_fields.map{|field_name, field| [field_name, field.label]}
    Hash[tuples].except(*csv_field_exclusions)
  end

  def document_to_csv_row(document, field_keys_to_labels)
    field_keys_to_labels.keys.map{ |field_key|
      next '' unless document.has?(field_key)
      values = document[field_key]
      values.first
    }
  end
end
