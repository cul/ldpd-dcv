module ChildrenHelper
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Dcv::ChildrenHelperBehavior
  def children(id=params[:id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id)
    document_children_from_model(opts)
  end
end