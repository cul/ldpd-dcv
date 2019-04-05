module Dcv::BlacklightHelperBehavior

  # Override so that this method doesn't always specify the catalog 'search_form' partial
  def render_search_bar(use_catalog_partial=true)
    render :partial => (use_catalog_partial ? 'catalog/search_form' : 'search_form')
  end

  def url_for_document doc, options = {}
    if respond_to?(:blacklight_config) and
        blacklight_config.show.route and
        (!doc.respond_to?(:to_model) or doc.to_model.is_a? SolrDocument)
      route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)
      route[:controller] = controller_path if route[:controller] == :current
      route
    else
      doc
    end
  end

  # see also Blacklight::BlacklightHelperBehavior#render_document_show_field_value
  def render_document_dynamic_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    presenter(document).render_document_dynamic_field_value field, options
  end
end
