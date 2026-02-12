module UrlHelper
  include Blacklight::UrlHelperBehavior

  def controller_tracking_method
    return blacklight_config.track_search_session.url_helper if blacklight_config.track_search_session.url_helper

    "track_site_#{controller_name}_path"
  end

   def solr_document_path(solr_document)
    url_for(params.to_unsafe_h.merge(action: "show", id: solr_document, site_id: controller.current_site.site_slug))
  end

  def solr_document_url(solr_document, options = {})
    search_state.url_for_document(solr_document, options)
  end
end
