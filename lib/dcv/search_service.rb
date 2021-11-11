class Dcv::SearchService < Blacklight::SearchService
  def search_builder
    return super unless context.dig(:builder, :addl_processor_chain)
    super.append(*context.dig(:builder, :addl_processor_chain))
  end

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def fetch(id = nil, extra_controller_params = {})
    return super unless extra_controller_params[:q]
    extra_controller_params[:q] = extra_controller_params[:q].sub('$ids', '$id')
    extra_controller_params[:q] << id
    # avoids fetch_one for more backwards-compatible fetch_many
    solr_response = fetch_many([], extra_controller_params).first
    [solr_response, solr_response.documents.first]
  end
end