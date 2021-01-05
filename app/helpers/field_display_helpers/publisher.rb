module FieldDisplayHelpers::Publisher
  def publisher_transformer(value)
    cache_key = repository_cache_key("publisher_ssim_to_short_title")

    transformation = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      map = {}
      solr_params = {
        qt: 'search',
        rows: 10000,
        fl: 'id,title_display_ssm,short_title_ssim',
        fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
        facet: false
      }
      response = doc_repository.connection.send_and_receive 'select', params: solr_params
      docs = response['response']['docs']
      docs.each do |doc|
        short_title = doc['short_title_ssim'] || doc['title_display_ssm']
        map["info:fedora/#{doc['id']}"] = short_title.first if short_title.present?
      end
      map
    end

    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def has_publisher?(field_config, document)
    publisher = document.fetch(:lib_publisher_ssm,[]).first
    return publisher.present?
  end

  def has_publication_info?(field_config, document)
    [:lib_publisher_ssm, :origin_info_place_for_display_ssm, field_config.field_name].detect { |fname| document[fname].present? }
  end
end
