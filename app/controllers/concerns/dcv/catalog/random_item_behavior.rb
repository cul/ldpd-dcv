module Dcv::Catalog::RandomItemBehavior
  extend ActiveSupport::Concern

  def get_random_item

    # First is just done for the purposes of getting a result count
    (response, document_list) = get_search_results(params, {:rows => 0})
    number_of_results = response['response']['numFound']

    # Re-do first query with a random offset to actually get a random result
    (response, document_list) = get_search_results(params, {:rows => 1, :start => Random.new.rand(0...number_of_results)})

    doc = document_list.first

    json_response = {
      'id' => doc.id,
      'thumbnail_url' => thumb_url(doc.id)
    }

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
