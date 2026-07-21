module TestRequestHelper
  # Parse an rspec test response object's json response body as openstruct
  def parse_resp(response)
    JSON.parse(response.body, object_class: OpenStruct)
  end
end