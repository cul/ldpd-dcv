module Dcv::CatalogHelperBehavior

  def url_for_children_data(per_page=nil)
    opts = {id: params[:id], controller: :children}
    opts[:per_page] = per_page || 4
    opts[:protocol] = (request.ssl?) ? 'https' : 'http'
    url_for(opts)
  end

  def parents(document=@document, extra_params={})
    fname = 'cul_member_of_ssim' #solr_name(:cul_member_of, :symbol)
    p_pids = Array.new(document[fname])
    p_pids.compact!
    p_pids.collect! {|p_pid| p_pid.split('/')[-1].sub(':','\:')}
    controller.fetch(p_pids, extra_params)[1]
  end

  def link_to_resource_in_context(document=@document)
    parents = parents(document)
    parents.collect do |parent|
      link_to(parent.fetch('title_display_ssm',[]).first, catalog_url(id:parent['id']))
    end
  end

  ##
  # Link to the previous document in the current search context
  def button_to_previous_document(previous_document, opts={})
    link_opts = session_tracking_params(previous_document, search_session['counter'].to_i - 1).merge(:class => "previous", :rel => 'prev')
    # raw(t('views.pagination.previous'))
    link_opts.merge!(opts)
    link_to_unless previous_document.nil?, '<i class="glyphicon glyphicon-arrow-left"></i>'.html_safe, url_for_document(previous_document), link_opts do
      if opts[:class]
        opts = opts.merge(class: opts[:class] + ' disabled')
      else
        opts = opts.merge(class: 'disabled')
      end
      content_tag :button, opts do
        content_tag :i, '', :class => 'glyphicon glyphicon-arrow-left'
      end
    end
  end

  ##
  # Link to the next document in the current search context
  def button_to_next_document(next_document, opts={})
    link_opts = session_tracking_params(next_document, search_session['counter'].to_i + 1).merge(:class => "next", :rel => 'next')
    # raw(t('views.pagination.next'))
    link_opts.merge!(opts)
    link_to_unless next_document.nil?, '<i class="glyphicon glyphicon-arrow-right"></i>'.html_safe, url_for_document(next_document), link_opts do
      if opts[:class]
        opts = opts.merge(class: opts[:class] + ' disabled')
      else
        opts = opts.merge(class: 'disabled')
      end
      content_tag :button, opts do
        content_tag :i, '', :class => 'glyphicon glyphicon-arrow-right'
      end
    end
  end

  def pcdm_file_genre_display value
    t("pcdm.file_genre.#{value}")
  end

  def rounded_down_and_formatted_dcv_asset_count
    rounded_down_and_formatted_dcv_object_count('total_dcv_asset_count', "active_fedora_model_ssi:GenericResource")
  end

  def rounded_down_and_formatted_dcv_item_count
    rounded_down_and_formatted_dcv_object_count('total_dcv_item_count', "active_fedora_model_ssi:ContentAggregator")
  end

  def rounded_down_and_formatted_dcv_object_count(cache_key='total_dcv_object_count', filter="active_fedora_model_ssi:(ContentAggregator OR GenericResource)")
    round_to_nearest = 1000 # e.g. round 12,345 down to nearest 1000: 12,000
    exact_total = total_dcv_object_count(cache_key, filter)
    return exact_total if exact_total < round_to_nearest

    count_to_return = exact_total / round_to_nearest * round_to_nearest
    number_with_delimiter(count_to_return.round(-3), :delimiter => ',')
  end

  def total_dcv_object_count(cache_key, filter)
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      solr_params = {
        qt: 'search',
        rows: 0,
        fq: [filter],
        facet: false
      }
      response = controller.repository.connection.send_and_receive 'select', params: solr_params
      response['response']['numFound'].to_i
    end
  end

  # Does this document represent an object with synchronized media?
  # @param document [Hash] the representative document
  # @return [Boolean]
  def has_synchronized_media?(document)
    (document.fetch(:datastreams_ssim, []) & ['chapters','synchronized_transcript']).present?
  end

  # Look up the label for the generated field
  def render_generated_field_label document, field_config
    field = field_config.field
    label = field_config.label
    if label.is_a? Symbol
      label = send label, document, field_config
    end
    t(:'blacklight.search.show.label', label: label)
  end

  def interview_metadata_for_asset(document = @document)
    published = parents(document).detect do |parent|
      parent['dc_type_ssm'].include?('InteractiveResource') && parent['ezid_doi_ssim'].present?
    end
    {
      'Title' => link_to(published['title_display_ssm'].first, controller: controller_name, action: :show, id: published['id']),
      'Date' => published['lib_date_textual_ssm'].first,
      'Identifier' => published['ezid_doi_ssim'].first
    }.compact
  end
end
