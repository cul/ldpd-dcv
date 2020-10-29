module Dcv::BlacklightHelperBehavior

  # Override so that this method doesn't always specify the shared 'search_form' partial
  def render_search_bar(use_shared_partial=false)
    render :partial => (use_shared_partial ? 'shared/search_form' : 'search_form')
  end

  def url_for_document doc, options = {}
    blc = blacklight_config if respond_to?(:blacklight_config)
    blc = controller.blacklight_config if respond_to?(:controller) && controller.respond_to?(:blacklight_config)
    if blc and blc.show.route and (!doc.respond_to?(:to_model) or doc.to_model.is_a? SolrDocument)
      route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)
      route[:controller] = controller_path if route[:controller] == :current
      route
    else
      doc
    end
  end

  # Override to accomodate proxies action
  def presenter(document)
    case action_name
    when 'show', 'citation', 'proxies', 'home'
      show_presenter(document)
    when 'index'
      index_presenter(document)
    else
      Deprecation.warn(Blacklight::BlacklightHelperBehavior, "Unable to determine presenter type for #{action_name} on #{controller_name}, falling back on deprecated Blacklight::DocumentPresenter")
      presenter_class.new(document, self)
    end
  end

  # see also Blacklight::BlacklightHelperBehavior#render_document_show_field_value
  def render_document_dynamic_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    presenter(document).render_document_dynamic_field_value field, options
  end

  # translate AF model names per previous behaviors
  def type_field_to_partial_name(document, display_type)
    super(document, "#{display_type.underscore}")
  end

  def document_link_params(doc, opts)
    if doc.site_result?
      super.merge(target: '_blank')
    else
      super
    end
  end

  def controller_tracking_method
    # "track_#{controller_name}_path"
    controller.tracking_method
  end
end
