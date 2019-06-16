module ChildrenHelper
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Dcv::ChildrenHelperBehavior
  def children(id=params[:parent_id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id)
    document_children_from_model(opts)
  end
  def child(id=params[:id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id, {fl: '*'})
    child_from_solr(@document)
  end
  def permitted_children(id=params[:parent_id], opts={})
  end
  def denied_children(id=params[:parent_id], opts={})
  end
end
