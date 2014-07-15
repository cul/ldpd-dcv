module Dcv::Catalog::RandomItemBehavior
  extend ActiveSupport::Concern

  # GET /catalog/get_random_item.json?param1=val1&param2=val2...&facets_to_return[]=facet_name_1&facets_to_return[]=facet_name_2
  def get_random_item

    # First is just done for the purposes of getting a result count
    (response, document_list) = get_search_results(params, {:rows => 0})
    number_of_results = response['response']['numFound']

    # Re-do first query with a random offset to actually get a random result
    (response, document_list) = get_search_results(params, {:rows => 1, :start => Random.new.rand(0...number_of_results)})

    doc = document_list.first

    # Handle facets if params[:facets_to_return].present?
    facet_data = {}
    if params[:facets_to_return].present?
      facets_to_return = params[:facets_to_return]

      if response['facet_counts'].present? && response['facet_counts']['facet_fields'].present?
        response['facet_counts']['facet_fields'].each do |facet_field_name, raw_facet_content_arr|

          if facets_to_return[0] == 'all' || facets_to_return.include?(facet_field_name)
            facet_data[facet_field_name] = {}
            raw_facet_content_arr.each_slice(2) do |value, count|
              facet_data[facet_field_name][value] = count
            end
          end

        end
      end
    end

    json_response = {
      'id' => doc.id,
      'title' => (doc['title_display_ssm'].present? ? doc['title_display_ssm'][0] : doc.id),
      'thumbnail_url' => thumb_url(doc.id)
    }
    json_response['facet_data'] = facet_data if params[:facets_to_return].present?

    respond_to do |format|
      format.json {
        render json: json_response
      }
      format.any {
        render :text => 'JSON is the only format available.', :status => 406
      }
    end

  end

end
