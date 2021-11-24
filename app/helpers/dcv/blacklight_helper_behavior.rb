module Dcv::BlacklightHelperBehavior

  def application_name
    @subsite&.title || super
  end

  # Override so that this method doesn't always specify the shared 'search_form' partial
  def render_search_bar(use_shared_partial=false)
    render :partial => (use_shared_partial ? 'shared/search_form' : 'search_form')
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

  def prev_next_link_opts(link_document, link_opts = {})
    session_tracking_params(link_document, search_session['counter'].to_i - 1).merge(link_opts)
  end

  # Override to use a disabled link when no doc
  # Link to the previous document in the current search context
  def link_to_previous_document(link_document)
    link_opts = { class: ["previous", "disabled"], rel: 'prev', disabled: true }
    doc_url = '#'
    if link_document
      link_opts = prev_next_link_opts(link_document, class: "previous", rel: 'prev', :'data-toggle' => 'tooltip')
      doc_url = url_for_document(link_document)
    end
    link_opts[:title] = t('views.pagination.previous')
    link_to doc_url, link_opts do
      content_tag :i, '', class: ['previous', 'fa', 'fa-arrow-left']
    end
  end

  # Override to use a disabled link when no doc
  # Link to the next document in the current search context
  def link_to_next_document(link_document)
    link_opts = { class: ["next", "disabled"], rel: 'next', disabled: true }
    doc_url = '#'
    if link_document
      link_opts = prev_next_link_opts(link_document, class: "next", rel: 'next', :'data-toggle' => 'tooltip')
      doc_url = url_for_document(link_document)
    end
    link_opts[:title] = t('views.pagination.next')
    link_to doc_url, link_opts do
      content_tag :i, '', class: ['previous', 'fa', 'fa-arrow-right']
    end
  end

end
