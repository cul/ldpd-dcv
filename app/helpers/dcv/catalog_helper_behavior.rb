module Dcv::CatalogHelperBehavior

  def url_for_children_data(per_page=nil)
    opts = {id: params[:id], controller: :children}
    opts[:per_page] = per_page || 4
    opts[:protocol] = (request.ssl?) ? 'https' : 'http'
    url_for(opts)
  end

  def format_value_transformer(value)
    transformation = {'resource' => 'File Asset', 'multipartitem' => 'Item', 'collection' => 'Collection'}
    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def publisher_transformer(value)

    transformation = Rails.cache.fetch('dcv.publisher_ssim_to_short_title', expires_in: 10.minutes) do
      map = {}
      Blacklight.solr.tap do |rsolr|
        solr_params = {
          qt: 'search',
          rows: 10000,
          fl: 'id,title_display_ssm,short_title_ssim',
          fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
          facet: false
        }
        response = rsolr.get 'select', :params => solr_params
        docs = response['response']['docs']
        docs.each do |doc|
          short_title = doc['short_title_ssim'] || doc['title_display_ssm']
          map["info:fedora/#{doc['id']}"] = short_title.first if short_title.present?
        end
      end

      map
    end

    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def parents(document=@document, extra_params={})
    fname = 'cul_member_of_ssim' #solr_name(:cul_member_of, :symbol)
    p_pids = Array.new(document[fname])
    p_pids.compact!
    p_pids.collect! {|p_pid| p_pid.split('/')[-1].sub(':','\:')}
    controller.get_solr_response_for_document_ids(p_pids, extra_params)[1]
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
end
