module Dcv::BlacklightHelperBehavior

  # Override so that this method doesn't always specify the catalog 'search_form' partial
  def render_search_bar(use_catalog_partial=true)
    render :partial => (use_catalog_partial ? 'catalog/search_form' : 'search_form')
  end

end
