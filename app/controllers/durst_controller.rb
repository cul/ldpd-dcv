class DurstController < SubsitesController

  helper_method :extract_map_data_from_document_list

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
    # Include only this target's content in search results
    config.default_solr_params[:fq] << "publisher_ssim:\"#{subsite_config['uri']}\""
  end

  def index
    super
    unless has_search_parameters?
      render 'home'
    end
  end

  def map_search

    @map_data_json = Rails.cache.fetch('map_data_json')
    if @map_data_json.nil?
      (@response, @document_list) = get_search_results(params, {:rows => 100000, :fl => 'id, geo, lib_format_ssm, title_display_ssm'}) # Calling get_search_results manually so that we always plot all points for the home page map
      cache_expiration_time = 12.hours
      map_data = extract_map_data_from_document_list(@document_list)
      @map_data_json = map_data.to_json
      Rails.cache.write('map_data_json', @map_data_json, expires_in: cache_expiration_time)
    end

  end

  def help
  end

  def favorites
    redirect_to '/durst?durst_favorites=true&search_field=all_text_teim'
  end

  def about_the_collection
  end

  def about_the_project
  end

  def acknowledgements
  end

  def old_york_library_collection_categories
  end

  private

  def extract_map_data_from_document_list(document_list)

    # We want this data to be as compact as possible because we're sending a lot to the client

    max_title_length = 50

    map_data = []
    document_list.each do |document|
      if document['geo'].present?
        document['geo'].each do |coordinates|

          lat_and_long = coordinates.split(',')

          is_book = document['lib_format_ssm'].present? && document['lib_format_ssm'].include?('books')

          title = document['title_display_ssm'][0].gsub(/\s+/, ' ') # Compress multiple spaces and new lines into one
          title = title[0,max_title_length].strip + '...' if title.length > max_title_length

          row = {
            id: document.id,
            c: lat_and_long[0].strip + ',' + lat_and_long[1].strip,
            t: title,
            b: is_book ? 'y' : 'n',
          }

          map_data << row
        end
      end
    end

    return map_data
  end

end
