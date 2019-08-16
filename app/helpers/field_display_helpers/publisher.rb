module FieldDisplayHelpers::Publisher
  def publisher_transformer(value)

    transformation = Rails.cache.fetch('dcv.publisher_ssim_to_short_title', expires_in: 10.minutes) do
      map = {}
      Blacklight.solr.tap do |rsolr|
        solr_params = {
          qt: 'search',
          rows: 10000,
          fl: 'id,title_display_ssm,short_title_ssim',
          fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
          facet: false
        }
        response = rsolr.get 'select', :params => solr_params
        docs = response['response']['docs']
        docs.each do |doc|
          short_title = doc['short_title_ssim'] || doc['title_display_ssm']
          map["info:fedora/#{doc['id']}"] = short_title.first if short_title.present?
        end
      end

      map
    end

    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end
end
