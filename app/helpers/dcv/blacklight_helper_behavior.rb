module Dcv::BlacklightHelperBehavior

  def application_name
    @subsite&.title || super
  end

  # will be removed in BL8, but it just renders the configured component
  def render_search_bar
    component_class = blacklight_config&.view_config(document_index_view_type)&.search_bar_component || Blacklight::SearchBarComponent
    render component_class.new(
      url: search_action_url,
      advanced_search_url: search_action_url(action: 'advanced_search'),
      params: search_state.params_for_search.except(:qt),
      search_fields: Deprecation.silence(Blacklight::ConfigurationHelperBehavior) { search_fields },
      autocomplete_path: search_action_path(action: :suggest)
    )
  end

  # Override to accomodate proxies action
  def document_presenter_class(document = nil)
    case action_name
    when 'show', 'proxies', 'home', 'details', 'embed'
      Dcv::ShowPresenter
    when 'citation'
      Dcv::CitationPresenter
    when 'index'
      Dcv::IndexPresenter
    else
      Deprecation.warn(Blacklight::BlacklightHelperBehavior, "Unable to determine presenter type for #{action_name} on #{controller_name}, falling back on deprecated Blacklight::DocumentPresenter")
      presenter_class.new(document, self)
    end
  end

  def citation_presenter_class(_document)
    Dcv::CitationPresenter
  end

  def citation_presenter(document)
    citation_presenter_class(document).new(document, self)
  end

  def geo_presenter_class(_document)
    Dcv::GeoPresenter
  end

  def geo_presenter(document)
    geo_presenter_class(document).new(document, self)
  end

  # translate AF model names per previous behaviors
  def type_field_to_partial_name(document, display_type)
    super(document, "#{display_type.underscore}")
  end

  def document_link_params(doc, opts)
    if doc.site_result?
      super.merge(target: '_blank')
    elsif action_name == 'home' # do not track homepage content searches
      return opts.except(:label, :counter)
    else
      super
    end
  end

  def controller_tracking_method
    # "track_#{controller_name}_path"
    controller.tracking_method
  end

  def prev_next_link_opts(link_document, delta, link_opts = {})
    session_tracking_params(link_document, search_session['counter'].to_i + delta).merge(link_opts)
  end

  # Override to use a disabled link when no doc
  # Link to the previous document in the current search context
  def link_to_previous_document(link_document, classes = "")
    link_opts = { class: "previous #{classes}".strip.split(' '), rel: 'prev', aria: { label: 'previous document' } }
    doc_url = '#'
    if link_document
      link_opts = prev_next_link_opts(link_document, -1, link_opts)
      doc_url = url_for_document(link_document)
    else
      link_opts.merge!(disabled: true, class: link_opts[:class] + ['disabled'])
    end
    link_to doc_url, link_opts do
      content_tag :i, '', class: ['previous', 'fa', 'fa-arrow-left'], title: t('views.pagination.previous'), :'data-toggle' => 'tooltip'
    end
  end

  # Override to use a disabled link when no doc
  # Link to the next document in the current search context
  def link_to_next_document(link_document, classes = "")
    link_opts = { class: "next #{classes}".strip.split(' '), rel: 'next', aria: { label: 'next document' } }
    doc_url = '#'
    if link_document
      link_opts = prev_next_link_opts(link_document, 1, link_opts)
      doc_url = url_for_document(link_document)
    else
      link_opts.merge!(disabled: true, class: link_opts[:class] + ['disabled'])
    end
    link_to doc_url, link_opts do
      content_tag :i, '', class: ['next', 'fa', 'fa-arrow-right'], title: t('views.pagination.next'), :'data-toggle' => 'tooltip'
    end
  end

  # Override to set controller based on actual current controller
  def link_back_to_catalog(opts = { label: nil })
    scope = opts.delete(:route_set) || self
    query_params = search_state.reset(current_search_session.try(:query_params)).to_hash
    query_params[:controller] = controller_path if controller.is_a? Dcv::Sites::SearchableController
    if search_session['counter']
      per_page = (search_session['per_page'] || blacklight_config.default_per_page).to_i
      counter = search_session['counter'].to_i

      query_params[:per_page] = per_page unless search_session['per_page'].to_i == blacklight_config.default_per_page
      query_params[:page] = ((counter - 1) / per_page) + 1
    end

    link_url = if query_params.empty?
                 search_action_path(only_path: true)
               else
                 scope.url_for(query_params)
               end
    label = opts.delete(:label)

    if link_url =~ /bookmarks/
      label ||= t('blacklight.back_to_bookmarks')
    end

    label ||= t('blacklight.back_to_search')

    link_to label, link_url, opts
  end
end
