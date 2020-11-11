module Dcv::Catalog::RandomItemBehavior
  extend ActiveSupport::Concern
  include Dcv::CdnHelper
  # GET /SUBSITE/random.json?param1=val1&param2=val2
  def random
    params.delete(:sort)
    (response, document_list) = search_results(params) do |builder|
      builder.merge(sort: "random_#{Random.new_seed} DESC")
    end

    doc = document_list.first

    json_response = document_list.map do |doc|
      {
        'id' => doc.id,
        'title' => (doc['title_display_ssm'].present? ? doc['title_display_ssm'][0] : doc.id),
        'thumbnail_url' => thumbnail_url(doc)
      }
    end
    json_response = json_response[0] if json_response.length == 1

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
